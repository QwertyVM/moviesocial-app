"use server";

import prisma from "@/lib/prisma";
import { CURATED_MOVIES } from "@/data/curatedMovies";
import { Movie } from "@/types";

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
 * Solo se considera "Estreno" a las películas que estén en sus primeras 2 semanas
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
 * Obtener películas estrictamente en periodo de estreno (primeras 2 semanas en cines).
 */
export async function getTheatricalMovies(countryCode: string = "PE"): Promise<Movie[]> {
  const code = (countryCode || "PE").toUpperCase();
  const tmdbKey = process.env.TMDB_API_KEY;

  if (tmdbKey) {
    try {
      const url = `https://api.themoviedb.org/3/movie/now_playing?api_key=${tmdbKey}&region=${code}&language=es-ES&page=1`;
      const res = await fetch(url, { next: { revalidate: 1800 } });
      if (res.ok) {
        const data = await res.json();
        if (data.results && Array.isArray(data.results)) {
          // Filtrar estrictamente por la regla de las 2 primeras semanas de emisión
          const activePremieres = data.results.filter((item: any) =>
            isWithinTwoWeeksWindow(item.release_date)
          );

          return activePremieres.map((item: any) => {
            const voteAvg = item.vote_average || 7.5;
            const genres = (item.genre_ids || [])
              .map((id: number) => TMDB_GENRES_MAP[id])
              .filter(Boolean);

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
              runtimeMinutes: 115,
              countryOfOrigin: code,
              ratings: {
                compositeScore: parseFloat(voteAvg.toFixed(1)),
                imdbScore: parseFloat(voteAvg.toFixed(1)),
                rottenTomatoesCritics: Math.min(100, Math.round(voteAvg * 10)),
                rottenTomatoesAudience: Math.min(100, Math.round(voteAvg * 10 + 2)),
              },
              isInTheatersLocally: true,
              theatersPlaying: CHAINS_BY_COUNTRY[code] || [`Cines comerciales (${code})`],
            };
          });
        }
      }
    } catch (tmdbError) {
      console.warn("Error consultando TMDB now_playing, usando catálogo local:", tmdbError);
    }
  }

  // Fallback: Filtrar catálogo curado que cumpla la regla de 2 semanas
  return CURATED_MOVIES.filter(
    (m) =>
      m.theatricalCountries &&
      m.theatricalCountries.includes(code) &&
      isWithinTwoWeeksWindow(m.releaseDate)
  ).map((m) => ({
    ...m,
    isInTheatersLocally: true,
    theatersPlaying: CHAINS_BY_COUNTRY[code] || [`Salas de cine (${code})`],
  }));
}

/**
 * Obtener catálogo global de películas fuera de estreno (que superaron las 2 semanas o lanzadas en digital),
 * ordenadas descendentemente por año/fecha.
 */
export async function getCatalogMovies(options?: {
  decade?: string;
  minRating?: number | null;
  genre?: string;
  sortBy?: "yearDesc" | "ratingDesc" | "criticsDesc" | "audienceDesc";
  searchQuery?: string;
  countryCode?: string;
}): Promise<Movie[]> {
  const {
    decade = "all",
    minRating = null,
    genre = "all",
    sortBy = "yearDesc",
    searchQuery = "",
    countryCode = "PE",
  } = options || {};

  const tmdbKey = process.env.TMDB_API_KEY;
  let tmdbPastMovies: Movie[] = [];

  // Obtener películas de TMDB que ya superaron las 2 semanas de estreno (como Michael, Obsession, etc.)
  if (tmdbKey) {
    try {
      const url = `https://api.themoviedb.org/3/movie/now_playing?api_key=${tmdbKey}&region=${countryCode}&language=es-ES&page=1`;
      const res = await fetch(url, { next: { revalidate: 1800 } });
      if (res.ok) {
        const data = await res.json();
        if (data.results && Array.isArray(data.results)) {
          // Las películas con más de 14 días pasan automáticamente al Catálogo Global
          const pastPremieres = data.results.filter(
            (item: any) => !isWithinTwoWeeksWindow(item.release_date)
          );

          tmdbPastMovies = pastPremieres.map((item: any) => {
            const voteAvg = item.vote_average || 7.5;
            const genres = (item.genre_ids || [])
              .map((id: number) => TMDB_GENRES_MAP[id])
              .filter(Boolean);

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
              runtimeMinutes: 115,
              countryOfOrigin: countryCode,
              ratings: {
                compositeScore: parseFloat(voteAvg.toFixed(1)),
                imdbScore: parseFloat(voteAvg.toFixed(1)),
                rottenTomatoesCritics: Math.min(100, Math.round(voteAvg * 10)),
                rottenTomatoesAudience: Math.min(100, Math.round(voteAvg * 10 + 2)),
              },
              isInTheatersLocally: false, // Fuera de estreno
              theatersPlaying: [],
            };
          });
        }
      }
    } catch (err) {
      console.warn("Error fetching tmdb catalog:", err);
    }
  }

  // Combinar catálogo local fuera de las 2 semanas con los títulos pasados de TMDB
  const localCatalog = CURATED_MOVIES.filter(
    (m) => !isWithinTwoWeeksWindow(m.releaseDate)
  ).map((m) => ({
    ...m,
    isInTheatersLocally: false,
  }));

  let list = [...tmdbPastMovies, ...localCatalog];

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
  if (genre && genre !== "all") {
    const norm = genre.toLowerCase();
    list = list.filter((m) => m.genres.some((g) => g.toLowerCase().includes(norm)));
  }

  // Buscador
  if (searchQuery.trim()) {
    const q = searchQuery.toLowerCase().trim();
    list = list.filter(
      (m) =>
        m.title.toLowerCase().includes(q) ||
        m.director?.toLowerCase().includes(q) ||
        m.genres.some((g) => g.toLowerCase().includes(q)) ||
        m.releaseYear.toString().includes(q)
    );
  }

  // Ordenamiento: Por defecto descendente desde la más actual fuera de estreno hasta la más antigua
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
 * Obtener detalle de película por ID (soporta IDs de TMDB 'tmdb_1234' y catálogo local).
 */
export async function getMovieByIdAction(id: string): Promise<Movie | null> {
  const tmdbKey = process.env.TMDB_API_KEY;

  if (id.startsWith("tmdb_") && tmdbKey) {
    try {
      const tmdbId = id.replace("tmdb_", "");
      const res = await fetch(
        `https://api.themoviedb.org/3/movie/${tmdbId}?api_key=${tmdbKey}&language=es-ES`
      );
      if (res.ok) {
        const item = await res.json();
        const voteAvg = item.vote_average || 7.5;
        const genres = (item.genres || []).map((g: any) => g.name);
        const isPremiering = isWithinTwoWeeksWindow(item.release_date);

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
          runtimeMinutes: item.runtime || 115,
          countryOfOrigin: item.origin_country?.[0] || "US",
          ratings: {
            compositeScore: parseFloat(voteAvg.toFixed(1)),
            imdbScore: parseFloat(voteAvg.toFixed(1)),
            rottenTomatoesCritics: Math.min(100, Math.round(voteAvg * 10)),
            rottenTomatoesAudience: Math.min(100, Math.round(voteAvg * 10 + 2)),
          },
          isInTheatersLocally: isPremiering,
          theatersPlaying: isPremiering ? (CHAINS_BY_COUNTRY["PE"] || ["Cines comerciales"]) : [],
        };
      }
    } catch (err) {
      console.warn("Error fetching tmdb movie detail:", err);
    }
  }

  const found = CURATED_MOVIES.find((m) => m.id === id);
  if (found) {
    const isPremiering = isWithinTwoWeeksWindow(found.releaseDate);
    return {
      ...found,
      isInTheatersLocally: isPremiering,
      theatersPlaying: isPremiering ? (CHAINS_BY_COUNTRY["PE"] || ["Cines comerciales"]) : [],
    };
  }
  return null;
}
