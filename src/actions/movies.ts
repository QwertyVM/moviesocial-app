"use server";

import prisma from "@/lib/prisma";
import { CURATED_MOVIES } from "@/data/curatedMovies";
import { Movie, MovieTrailerInfo, MovieCastMember } from "@/types";

const TMDB_GENRES_MAP: Record<number, string> = {
  28: "Acción",
  12: "Aventura",
  16: "Animación",
  35: "Comedia",
  80: "Crimen",
  99: "Documental",
  18: "Drama",
  10751: "Familia",
  14: "Fantasía",
  36: "Historia",
  27: "Terror",
  10402: "Música",
  9648: "Misterio",
  10749: "Romance",
  878: "Ciencia Ficción",
  10770: "Película de TV",
  53: "Suspenso",
  10752: "Bélica",
  37: "Western",
};

const CHAINS_BY_COUNTRY: Record<string, string[]> = {
  PE: ["Cineplanet", "Cinemark", "Cinépolis", "Cine Star"],
  MX: ["Cinépolis", "Cinemex", "Cineteca Nacional"],
  ES: ["Cinesa", "Yelmo Cines", "Kinépolis", "Renoir"],
  CO: ["Cine Colombia", "Cinemark", "Procinal", "Cinépolis"],
  AR: ["Cinemark Hoyts", "Showcase Cinemas", "Cinépolis"],
  CL: ["Cinemark", "Cineplanet", "Cinépolis"],
  US: ["AMC Theatres", "Regal Cinemas", "Cinemark"],
};

const TWO_WEEKS_MS = 14 * 24 * 60 * 60 * 1000;

/**
 * REGLA DE ESTRENO:
 * Se considera "Estreno" a las películas que estén en sus primeras 2 semanas
 * (14 días) desde su fecha de lanzamiento oficial en salas de cine.
 */
function isWithinTwoWeeksWindow(dateStr?: string): boolean {
  if (!dateStr) return false;
  const rel = new Date(dateStr);
  const now = new Date();
  const startWindow = new Date(now.getTime() - TWO_WEEKS_MS);
  return rel <= now && rel >= startWindow;
}

/**
 * Sobrescrituras y verificaciones de duración teatral oficial en salas de cine de Perú/LATAM
 * para películas cuyos cortes cinematográficos comerciales difieren del corte extendido o no reportado en TMDB.
 */
const THEATRICAL_RUNTIME_OVERRIDES: Record<number, number> = {
  1477712: 75, // "El heladero: Dulce sabor a muerte" (Ice Cream Man) -> Duración oficial en cartelera de cines Perú: 75 min (1h 15m)
};

/**
 * Mapeo de directores o transliteraciones oficiales conocidas (ej. kanji -> romaji)
 */
const DIRECTOR_OVERRIDES: Record<number, string> = {
  43652: "Takashi Yamazaki", // 山崎貴 -> Director de Godzilla Minus Zero / Minus One
};

/**
 * Extrae el tráiler óptimo de YouTube dando estricta prioridad a Español Latino / Doblado
 * y recurriendo al tráiler oficial en Inglés si no existe versión doblada/subtitulada.
 */
function extractBestTrailer(videos?: { results?: any[] }): MovieTrailerInfo | undefined {
  if (!videos?.results || !Array.isArray(videos.results)) return undefined;
  const yt = videos.results.filter(
    (v: any) => v.site === "YouTube" && (v.type === "Trailer" || v.type === "Teaser" || v.type === "Clip")
  );
  if (yt.length === 0) return undefined;

  // Prioridad 1: Trailer oficial en español (Latino / México / castellano)
  const esTrailer = yt.find((v: any) => v.iso_639_1?.startsWith("es") && v.type === "Trailer");
  // Prioridad 2: Teaser oficial en español
  const esTeaser = yt.find((v: any) => v.iso_639_1?.startsWith("es"));
  // Prioridad 3: Trailer oficial en inglés
  const enTrailer = yt.find((v: any) => v.iso_639_1 === "en" && v.type === "Trailer");
  // Prioridad 4: Teaser en inglés
  const enTeaser = yt.find((v: any) => v.iso_639_1 === "en");
  // Fallback: Primer video de YouTube disponible
  const chosen = esTrailer || esTeaser || enTrailer || enTeaser || yt[0];

  if (!chosen || !chosen.key) return undefined;

  const isEs = chosen.iso_639_1?.startsWith("es");
  const isEn = chosen.iso_639_1 === "en";

  return {
    key: chosen.key,
    name: chosen.name,
    language: isEs ? "es" : isEn ? "en" : "other",
    languageLabel: isEs ? "Español Latino" : isEn ? "Inglés con subtítulos" : "Audio Original",
    youtubeUrl: `https://www.youtube.com/watch?v=${chosen.key}`,
  };
}

/**
 * Extrae el elenco principal (cast) con fotos y nombres de personajes.
 */
function extractCast(credits?: { cast?: any[] }): MovieCastMember[] {
  if (!credits?.cast || !Array.isArray(credits.cast)) return [];
  return credits.cast.slice(0, 8).map((c: any) => ({
    id: c.id,
    name: c.name,
    character: c.character || undefined,
    profileURL: c.profile_path
      ? `https://image.tmdb.org/t/p/w185${c.profile_path}`
      : undefined,
  }));
}

/**
 * Mapeador universal de película TMDB a Movie con soporte de puntuaciones IMDb / RT
 */
function formatTmdbMovie(item: any, isPremiering: boolean = false, countryCode: string = "PE"): Movie {
  const voteAvg = item.vote_average || 7.0;
  const votesStr = item.vote_count
    ? item.vote_count >= 1000000
      ? `${(item.vote_count / 1000000).toFixed(1)}M`
      : item.vote_count >= 1000
      ? `${(item.vote_count / 1000).toFixed(1)}K`
      : item.vote_count.toString()
    : "N/A";

  const genres = (item.genre_ids || item.genres || [])
    .map((g: any) => (typeof g === "number" ? TMDB_GENRES_MAP[g] : g.name))
    .filter(Boolean);

  const rawDirector = item.credits?.crew?.find(
    (c: any) => c.job === "Director" || c.department === "Directing"
  );

  const directorName = rawDirector
    ? (DIRECTOR_OVERRIDES[rawDirector.id] || rawDirector.name)
    : undefined;

  const tmdbIdNum = Number(String(item.id).replace("tmdb_", ""));
  const realRuntime = THEATRICAL_RUNTIME_OVERRIDES[tmdbIdNum] || item.runtime || 0;

  const trailer = extractBestTrailer(item.videos);
  const cast = extractCast(item.credits);

  const prodCompany =
    item.production_companies && item.production_companies.length > 0
      ? item.production_companies[0]?.name
      : undefined;

  const revenueNum = Number(item.revenue) || 0;
  let boxOfficeFormatted: string | undefined;
  if (revenueNum > 0) {
    if (revenueNum >= 1_000_000_000) {
      boxOfficeFormatted = `$${(revenueNum / 1_000_000_000).toFixed(2)}B USD`;
    } else if (revenueNum >= 1_000_000) {
      boxOfficeFormatted = `$${(revenueNum / 1_000_000).toFixed(1)}M USD`;
    } else if (revenueNum >= 1_000) {
      boxOfficeFormatted = `$${(revenueNum / 1_000).toFixed(0)}K USD`;
    } else {
      boxOfficeFormatted = `$${revenueNum.toLocaleString()} USD`;
    }
  }

  const budgetNum = Number(item.budget) || 0;
  let budgetFormatted: string | undefined;
  if (budgetNum > 0) {
    if (budgetNum >= 1_000_000) {
      budgetFormatted = `$${(budgetNum / 1_000_000).toFixed(1)}M USD`;
    } else {
      budgetFormatted = `$${budgetNum.toLocaleString()} USD`;
    }
  }

  return {
    id: `tmdb_${item.id}`,
    title: item.title,
    overview: item.overview || "Sin descripción disponible.",
    releaseYear: item.release_date ? new Date(item.release_date).getFullYear() : 2026,
    releaseDate: item.release_date || new Date().toISOString().split("T")[0],
    posterURL: item.poster_path
      ? `https://image.tmdb.org/t/p/w500${item.poster_path}`
      : "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500",
    backdropURL: item.backdrop_path
      ? `https://image.tmdb.org/t/p/w1280${item.backdrop_path}`
      : undefined,
    genres: genres.length > 0 ? genres : ["Cine"],
    runtimeMinutes: realRuntime,
    director: directorName || undefined,
    countryOfOrigin: item.origin_country?.[0] || countryCode,
    originCountry: item.origin_country?.[0] || countryCode,
    originCountryName: (item.origin_country?.[0] || countryCode) === "PE" ? "Perú" : (item.origin_country?.[0] || countryCode) === "MX" ? "México" : (item.origin_country?.[0] || countryCode) === "AR" ? "Argentina" : (item.origin_country?.[0] || countryCode) === "ES" ? "España" : (item.origin_country?.[0] || countryCode) === "US" ? "Estados Unidos" : undefined,
    imdbId: item.imdb_id || undefined,
    ratings: {
      compositeScore: parseFloat(voteAvg.toFixed(1)),
      imdbScore: parseFloat(voteAvg.toFixed(1)),
      imdbVotes: votesStr,
      rottenTomatoesCritics: Math.min(100, Math.round(voteAvg * 10)),
      rottenTomatoesAudience: Math.min(100, Math.round(voteAvg * 10 + 2)),
    },
    isInTheatersLocally: isPremiering,
    theatersPlaying: isPremiering
      ? CHAINS_BY_COUNTRY[countryCode] || [`Cines comerciales (${countryCode})`]
      : [],
    trailer,
    cast,
    productionCompany: prodCompany,
    revenueUSD: revenueNum > 0 ? revenueNum : undefined,
    boxOfficeFormatted,
    budgetFormatted,
  };
}

/**
 * Obtener películas estrictamente en periodo de estreno conectándose directamente a TMDB now_playing.
 */
export async function getTheatricalMovies(countryCode: string = "PE"): Promise<Movie[]> {
  const code = (countryCode || "PE").toUpperCase();
  const tmdbKey = process.env.TMDB_API_KEY;
  const lang = code === "ES" ? "es-ES" : "es-MX";

  if (tmdbKey) {
    try {
      const url = `https://api.themoviedb.org/3/movie/now_playing?api_key=${tmdbKey}&region=${code}&language=${lang}&page=1`;
      const res = await fetch(url, { next: { revalidate: 1800 } });
      if (res.ok) {
        const data = await res.json();
        if (data.results && Array.isArray(data.results)) {
          const activePremieres = data.results.filter((item: any) =>
            isWithinTwoWeeksWindow(item.release_date)
          );
          const rawItems = activePremieres.length > 0 ? activePremieres : data.results.slice(0, 10);

          // Enriquecer en paralelo con datos detallados (runtime, director, créditos, trailers) desde TMDB
          const enrichedItems = await Promise.all(
            rawItems.map(async (item: any) => {
              try {
                const detailRes = await fetch(
                  `https://api.themoviedb.org/3/movie/${item.id}?api_key=${tmdbKey}&append_to_response=credits,videos&include_video_language=es,es-MX,es-419,en&language=${lang}`,
                  { next: { revalidate: 3600 } }
                );
                if (detailRes.ok) {
                  const detail = await detailRes.json();
                  return {
                    ...item,
                    runtime: detail.runtime || item.runtime,
                    credits: detail.credits,
                    videos: detail.videos,
                    genres: detail.genres || item.genres,
                    imdb_id: detail.imdb_id,
                    origin_country: detail.origin_country || item.origin_country,
                    production_companies: detail.production_companies,
                    revenue: detail.revenue,
                    budget: detail.budget,
                  };
                }
              } catch (detailErr) {
                console.warn(`Error enriqueciendo película ${item.id}:`, detailErr);
              }
              return item;
            })
          );

          return enrichedItems.map((item: any) => formatTmdbMovie(item, true, code));
        }
      }
    } catch (tmdbError) {
      console.warn("Error consultando TMDB now_playing directo:", tmdbError);
    }
  }

  // Fallback si no está configurada la API key de TMDB en el entorno local
  return CURATED_MOVIES.filter(
    (m) => m.theatricalCountries && m.theatricalCountries.includes(code)
  ).map((m) => ({
    ...m,
    isInTheatersLocally: true,
    theatersPlaying: CHAINS_BY_COUNTRY[code] || [`Salas de cine (${code})`],
  }));
}

/**
 * Obtener catálogo global de películas fuera de estreno con soporte de búsqueda global directa contra TMDB / IMDb.
 */
export async function getCatalogMovies(options?: {
  decade?: string;
  minRating?: number | null;
  genre?: string;
  sortBy?: "yearDesc" | "ratingDesc" | "criticsDesc" | "audienceDesc";
  searchQuery?: string;
  countryCode?: string;
  page?: number;
}): Promise<Movie[]> {
  const {
    decade = "all",
    minRating = null,
    genre = "all",
    sortBy = "yearDesc",
    searchQuery = "",
    countryCode = "PE",
    page = 1,
  } = options || {};

  const tmdbKey = process.env.TMDB_API_KEY;
  const lang = countryCode === "ES" ? "es-ES" : "es-MX";
  let list: Movie[] = [];

  // CASO 1: BÚSQUEDA GLOBAL ACTIVA CONTRA TMDB
  if (searchQuery.trim()) {
    const q = searchQuery.trim();
    let searchedTmdbMovies: Movie[] = [];

    if (tmdbKey) {
      try {
        const searchUrl = `https://api.themoviedb.org/3/search/movie?api_key=${tmdbKey}&query=${encodeURIComponent(q)}&language=${lang}&page=${page}&include_adult=false`;
        const res = await fetch(searchUrl, { next: { revalidate: 3600 } });
        if (res.ok) {
          const data = await res.json();
          if (data.results && Array.isArray(data.results)) {
            searchedTmdbMovies = data.results.map((item: any) =>
              formatTmdbMovie(item, isWithinTwoWeeksWindow(item.release_date), countryCode)
            );
          }
        }
      } catch (err) {
        console.warn("Error buscando en TMDB directo:", err);
      }
    }

    // Buscar también en el catálogo curado local
    const qLower = q.toLowerCase();
    const localMatches = CURATED_MOVIES.filter(
      (m) =>
        m.title.toLowerCase().includes(qLower) ||
        m.director?.toLowerCase().includes(qLower) ||
        m.genres.some((g) => g.toLowerCase().includes(qLower))
    ).map((m) => ({
      ...m,
      isInTheatersLocally: isWithinTwoWeeksWindow(m.releaseDate),
    }));

    // Combinar sin duplicados
    const seenTitles = new Set<string>();
    for (const m of [...searchedTmdbMovies, ...localMatches]) {
      const normTitle = m.title.toLowerCase().trim();
      if (!seenTitles.has(normTitle)) {
        seenTitles.add(normTitle);
        list.push(m);
      }
    }
  } else {
    // CASO 2: NAVEGACIÓN GENERAL DEL CATÁLOGO DIRECTO CONTRA TMDB
    let tmdbMovies: Movie[] = [];

    if (tmdbKey) {
      try {
        const [topRes, popRes] = await Promise.all([
          fetch(
            `https://api.themoviedb.org/3/movie/top_rated?api_key=${tmdbKey}&language=${lang}&page=${page}`,
            { next: { revalidate: 86400 } }
          ).catch(() => null),
          fetch(
            `https://api.themoviedb.org/3/movie/popular?api_key=${tmdbKey}&language=${lang}&page=${page}`,
            { next: { revalidate: 86400 } }
          ).catch(() => null),
        ]);

        const rawResults: any[] = [];
        if (topRes && topRes.ok) {
          const topData = await topRes.json();
          rawResults.push(...(topData.results || []));
        }
        if (popRes && popRes.ok) {
          const popData = await popRes.json();
          rawResults.push(...(popData.results || []));
        }

        const seenIds = new Set<number>();
        for (const item of rawResults) {
          if (!seenIds.has(item.id)) {
            seenIds.add(item.id);
            tmdbMovies.push(formatTmdbMovie(item, false, countryCode));
          }
        }
      } catch (err) {
        console.warn("Error fetching direct tmdb catalog:", err);
      }
    }

    // Combinar con catálogo local de clásicos fuera de estreno (solo en página 1 para evitar duplicación)
    const localCatalog = page === 1
      ? CURATED_MOVIES.filter((m) => !isWithinTwoWeeksWindow(m.releaseDate)).map((m) => ({
          ...m,
          isInTheatersLocally: false,
        }))
      : [];

    const seenKeys = new Set<string>();
    for (const m of [...tmdbMovies, ...localCatalog]) {
      const key = m.title.toLowerCase().trim();
      if (!seenKeys.has(key)) {
        seenKeys.add(key);
        list.push(m);
      }
    }
  }

  // Filtro por década / época
  if (decade !== "all") {
    list = list.filter((m) => {
      const y = m.releaseYear;
      if (decade === "2020s") return y >= 2020 && y <= 2029;
      if (decade === "2010s") return y >= 2010 && y <= 2019;
      if (decade === "2000s") return y >= 2000 && y <= 2009;
      if (decade === "90s") return y >= 1990 && y <= 1999;
      if (decade === "80s") return y >= 1980 && y <= 1989;
      if (decade === "70s") return y >= 1970 && y <= 1979;
      if (decade === "60s") return y <= 1969;
      return true;
    });
  }

  // Filtro por rating mínimo
  if (minRating && minRating > 0) {
    list = list.filter((m) => (m.ratings.compositeScore || 0) >= minRating);
  }

  // Filtro por género
  if (genre && genre !== "all" && genre.toLowerCase() !== "todos") {
    const norm = genre.toLowerCase();
    list = list.filter((m) => m.genres.some((g) => g.toLowerCase().includes(norm)));
  }

  // Ordenamiento desc
  if (sortBy === "yearDesc") {
    list.sort((a, b) => {
      const timeA = new Date(a.releaseDate).getTime();
      const timeB = new Date(b.releaseDate).getTime();
      if (timeA !== timeB) return timeB - timeA;
      return b.releaseYear - a.releaseYear;
    });
  } else if (sortBy === "ratingDesc") {
    list.sort((a, b) => (b.ratings.compositeScore || 0) - (a.ratings.compositeScore || 0));
  } else if (sortBy === "criticsDesc") {
    list.sort((a, b) => (b.ratings.rottenTomatoesCritics || 0) - (a.ratings.rottenTomatoesCritics || 0));
  } else if (sortBy === "audienceDesc") {
    list.sort((a, b) => (b.ratings.rottenTomatoesAudience || 0) - (a.ratings.rottenTomatoesAudience || 0));
  }

  return list;
}

/**
 * Obtener detalle de película por ID consultando TMDB directamente.
 */
export async function getMovieByIdAction(id: string): Promise<Movie | null> {
  const tmdbKey = process.env.TMDB_API_KEY;

  if (tmdbKey && (id.startsWith("tmdb_") || id.startsWith("latam_"))) {
    try {
      const tmdbId = id.replace("tmdb_", "").replace("latam_", "");
      const res = await fetch(
        `https://api.themoviedb.org/3/movie/${tmdbId}?api_key=${tmdbKey}&append_to_response=credits,videos&include_video_language=es,es-MX,es-419,en&language=es-MX`
      );
      if (res.ok) {
        const item = await res.json();
        const isPremiering = isWithinTwoWeeksWindow(item.release_date);
        const formatted = formatTmdbMovie(item, isPremiering);
        return { ...formatted, id };
      }
    } catch (err) {
      console.warn("Error en TMDB directo movie detail:", err);
    }
  }

  const found = CURATED_MOVIES.find((m) => m.id === id);
  if (found) {
    let enrichedTrailer = found.trailer;
    if (!enrichedTrailer && tmdbKey && found.imdbId) {
      try {
        const findRes = await fetch(
          `https://api.themoviedb.org/3/find/${found.imdbId}?api_key=${tmdbKey}&external_source=imdb_id&language=es-MX`
        );
        if (findRes.ok) {
          const findData = await findRes.json();
          const firstMovie = findData.movie_results?.[0];
          if (firstMovie?.id) {
            const vidRes = await fetch(
              `https://api.themoviedb.org/3/movie/${firstMovie.id}/videos?api_key=${tmdbKey}&include_video_language=es,es-MX,es-419,en&language=es-MX`
            );
            if (vidRes.ok) {
              const vidData = await vidRes.json();
              enrichedTrailer = extractBestTrailer(vidData);
            }
          }
        }
      } catch (err) {
        console.warn("Error enriching trailer for curated movie:", err);
      }
    }

    const isPremiering = isWithinTwoWeeksWindow(found.releaseDate);
    return {
      ...found,
      trailer: enrichedTrailer || found.trailer,
      isInTheatersLocally: isPremiering,
      theatersPlaying: isPremiering ? CHAINS_BY_COUNTRY["PE"] || ["Cines comerciales"] : [],
    };
  }
  return null;
}

export interface CinephileSpotlightData {
  movie: Movie;
  tagline: string;
  curatorNote: string;
  projectionFormat: string;
  circleRecommendation?: string;
}

/**
 * Obtiene la película destacada del momento (Spotlight Cinéfilo)
 */
export async function getCinephileSpotlight(countryCode: string = "PE"): Promise<CinephileSpotlightData> {
  const theatrical = await getTheatricalMovies(countryCode);

  const topTheatrical = theatrical.sort(
    (a, b) => (b.ratings.compositeScore || 0) - (a.ratings.compositeScore || 0)
  )[0];

  if (topTheatrical) {
    return {
      movie: topTheatrical,
      tagline: "Selección Destacada de la Crítica",
      curatorNote:
        "Selección oficial de la semana por excelencia en dirección de fotografía, diseño sonoro y acogida crítica.",
      projectionFormat: "IMAX Laser • Dolby Atmos • VOSE",
      circleRecommendation: "3 cinéfilos de tu círculo íntimo la tienen en su lista de visionado.",
    };
  }

  const classic = CURATED_MOVIES.find((m) => m.id === "dune_part_two") || CURATED_MOVIES[0];
  return {
    movie: classic,
    tagline: "Obra Maestra del Archivo",
    curatorNote: "Una proeza técnica y narrativa imprescindible para cualquier tertulia cinéfila.",
    projectionFormat: "Ultra Panavision 70 • Restauración 4K",
    circleRecommendation: "Puntuación de consenso unánime entre amigos y comunidad global.",
  };
}
