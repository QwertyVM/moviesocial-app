"use client";

import React, { useState, useEffect } from "react";
import { Movie, User, UserLocation, calculateCompositeScore } from "../types";
import { api } from "../services/api";
import {
  Globe,
  Search,
  Film,
  Sparkles,
  Star,
  Clapperboard,
  Eye,
  Bookmark,
  LayoutGrid,
  List,
  Trophy,
  Award,
  Flame,
  Check,
  CheckCircle2,
  Plus,
  Compass,
  X,
} from "lucide-react";

interface ArchiveViewProps {
  currentUser?: User | null;
  location?: UserLocation;
  onSelectMovie: (movie: Movie) => void;
  onOpenAuthModal?: (mode: "login" | "register", reason?: string) => void;
}

const COLLECTIONS = [
  { id: "all", label: "Todas las Obras", icon: Sparkles },
  { id: "latam", label: "Cine Latinoamericano", icon: Compass },
  { id: "top250", label: "Top Histórico ★", icon: Trophy },
  { id: "awards", label: "Premios & Festivales", icon: Award },
  { id: "cult", label: "Joyas de Culto", icon: Flame },
];

const COUNTRIES = [
  { id: "all", label: "Todos los Países" },
  { id: "PE", label: "🇵🇪 Perú" },
  { id: "MX", label: "🇲🇽 México" },
  { id: "AR", label: "🇦🇷 Argentina" },
  { id: "ES", label: "🇪🇸 España" },
  { id: "CO", label: "🇨🇴 Colombia" },
  { id: "CL", label: "🇨🇱 Chile" },
  { id: "BR", label: "🇧🇷 Brasil" },
  { id: "US", label: "🇺🇸 Estados Unidos" },
  { id: "JP", label: "🇯🇵 Japón" },
  { id: "KR", label: "🇰🇷 Corea del Sur" },
  { id: "FR", label: "🇫🇷 Francia" },
  { id: "IT", label: "🇮🇹 Italia" },
  { id: "GB", label: "🇬🇧 Reino Unido" },
];

const DECADES = [
  { id: "all", label: "Todas las épocas" },
  { id: "2020s", label: "2020s (Actual)" },
  { id: "2010s", label: "2010s" },
  { id: "2000s", label: "2000s" },
  { id: "90s", label: "Años 90" },
  { id: "80s", label: "Años 80" },
  { id: "70s", label: "Años 70" },
  { id: "60s", label: "Clásicos (<1970)" },
];

const GENRES = [
  "Todos",
  "Drama",
  "Ciencia Ficción",
  "Terror",
  "Suspenso",
  "Comedia",
  "Acción",
  "Animación",
  "Romance",
];

// Metas progresivas alcanzables (no requiere ver todas las películas para llegar al 100%)
const CINEPHILE_TIERS = [
  { level: 1, title: "Iniciado del Cine", badge: "🥉", target: 3, desc: "Meta inicial: 3 películas" },
  { level: 2, title: "Cinéfilo Activo", badge: "🥈", target: 6, desc: "Siguiente meta: 6 películas" },
  { level: 3, title: "Crítico de Tertulia", badge: "🥇", target: 10, desc: "Meta avanzada: 10 películas" },
  { level: 4, title: "Maestro de Filmoteca", badge: "👑", target: 15, desc: "Meta de élite: 15 películas" },
  { level: 5, title: "Leyenda Cinéfila", badge: "🌟", target: 20, desc: "Meta máxima: 20 películas" },
];

export const ArchiveView: React.FC<ArchiveViewProps> = ({
  currentUser,
  location,
  onSelectMovie,
  onOpenAuthModal,
}) => {
  const activeLocation =
    location ||
    currentUser?.location || {
      city: "Lima",
      country: "Perú",
      countryCode: "PE",
      flagEmoji: "🇵🇪",
      isLocal: true,
      area: "Lima",
    };

  // Filtros y búsqueda
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCollection, setSelectedCollection] = useState("all");
  const [selectedCountry, setSelectedCountry] = useState("all");
  const [selectedDirector, setSelectedDirector] = useState<string | null>(null);
  const [selectedDecade, setSelectedDecade] = useState("all");
  const [selectedGenre, setSelectedGenre] = useState("Todos");
  const [sortBy, setSortBy] = useState<"ratingDesc" | "yearDesc" | "criticsDesc" | "audienceDesc">("ratingDesc");

  // Modo de visualización (Grilla vs Lista 2-por-fila)
  const [viewMode, setViewMode] = useState<"grid" | "list">("list");

  // Registro de imágenes con error de carga
  const [brokenImageIds, setBrokenImageIds] = useState<Set<string>>(new Set());

  // Películas y paginación
  const [movies, setMovies] = useState<Movie[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSearching, setIsSearching] = useState(false);
  const [page, setPage] = useState(1);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);

  // Estados interactivos rápidos del usuario
  const [watchlistIds, setWatchlistIds] = useState<Set<string>>(new Set());
  const [watchedIds, setWatchedIds] = useState<Set<string>>(new Set());
  const [userRatings, setUserRatings] = useState<Record<string, number>>({});
  const [activeRatingPopover, setActiveRatingPopover] = useState<string | null>(null);
  const [ratingSuccessMovie, setRatingSuccessMovie] = useState<string | null>(null);

  // Cargar Watchlist inicial si hay usuario
  useEffect(() => {
    if (currentUser?.id) {
      api.getWatchlist(currentUser.id).then((ids) => {
        setWatchlistIds(new Set(ids));
      });
    } else {
      setWatchlistIds(new Set());
      setWatchedIds(new Set());
      setUserRatings({});
    }
  }, [currentUser?.id]);

  // Cargar películas (reset o búsqueda inicial)
  const fetchArchive = async (queryText: string, pageNum: number = 1, append: boolean = false) => {
    if (!append) {
      if (queryText.trim()) setIsSearching(true);
      else setLoading(true);
    } else {
      setIsLoadingMore(true);
    }

    try {
      const genreParam = selectedGenre === "Todos" ? "all" : selectedGenre;
      const url = `/api/movies/catalog?page=${pageNum}&country=${activeLocation.countryCode}&decade=${selectedDecade}&genre=${genreParam}&sortBy=${sortBy}${
        queryText.trim() ? `&q=${encodeURIComponent(queryText.trim())}` : ""
      }`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        const incoming: Movie[] = data.movies || [];

        if (append) {
          setMovies((prev) => {
            const seen = new Set(prev.map((m) => m.id));
            const fresh = incoming.filter((m) => !seen.has(m.id));
            if (fresh.length === 0) setHasMore(false);
            return [...prev, ...fresh];
          });
        } else {
          setMovies(incoming);
          setHasMore(incoming.length >= 10);
        }
      }
    } catch (err) {
      console.warn("Error cargando filmoteca:", err);
    } finally {
      setLoading(false);
      setIsSearching(false);
      setIsLoadingMore(false);
    }
  };

  // Debounced search trigger (resetea a página 1)
  useEffect(() => {
    setPage(1);
    setHasMore(true);
    const timer = setTimeout(() => {
      fetchArchive(searchQuery, 1, false);
    }, 320);
    return () => clearTimeout(timer);
  }, [searchQuery, selectedDecade, selectedGenre, sortBy, activeLocation.countryCode]);

  // Handler: Cargar 20 películas más
  const handleLoadMore = async () => {
    if (isLoadingMore || !hasMore) return;
    const nextPage = page + 1;
    setPage(nextPage);
    await fetchArchive(searchQuery, nextPage, true);
  };

  // Filtrado reactivo en cliente (Director, País y Colecciones Especiales)
  const displayedMovies = movies.filter((m) => {
    // 0. Filtro interactivo por Director
    if (selectedDirector && selectedDirector.trim()) {
      if (!m.director || !m.director.toLowerCase().includes(selectedDirector.toLowerCase())) {
        return false;
      }
    }

    // 1. Filtro por País de origen
    if (selectedCountry !== "all") {
      const code = (m.countryOfOrigin || m.originCountry || "").toUpperCase();
      const name = (m.originCountryName || "").toLowerCase();
      const isCountryMatch =
        code === selectedCountry ||
        (selectedCountry === "PE" && (name.includes("perú") || name.includes("peru") || m.id.includes("pe") || m.id.includes("latam_28644") || m.id.includes("latam_511425"))) ||
        (selectedCountry === "MX" && (name.includes("méxico") || name.includes("mexico") || m.id.includes("latam_55") || m.id.includes("latam_1417") || m.id.includes("latam_426426"))) ||
        (selectedCountry === "AR" && (name.includes("argentina") || m.id.includes("latam_25376") || m.id.includes("latam_265195"))) ||
        (selectedCountry === "ES" && (name.includes("españa") || name.includes("spain") || m.id.includes("latam_99"))) ||
        (selectedCountry === "CO" && (name.includes("colombia") || m.id.includes("latam_336808"))) ||
        (selectedCountry === "CL" && (name.includes("chile") || m.id.includes("latam_12086"))) ||
        (selectedCountry === "BR" && (name.includes("brasil") || name.includes("brazil") || m.id.includes("latam_598"))) ||
        (selectedCountry === "US" && (name.includes("estados unidos") || name.includes("usa") || code === "US")) ||
        (selectedCountry === "JP" && (name.includes("japón") || name.includes("japon") || name.includes("japan") || code === "JP")) ||
        (selectedCountry === "KR" && (name.includes("corea") || name.includes("korea") || code === "KR")) ||
        (selectedCountry === "FR" && (name.includes("francia") || name.includes("france") || code === "FR")) ||
        (selectedCountry === "IT" && (name.includes("italia") || name.includes("italy") || code === "IT")) ||
        (selectedCountry === "GB" && (name.includes("reino unido") || name.includes("uk") || code === "GB"));

      if (!isCountryMatch) return false;
    }

    // 2. Filtro por Colecciones Especiales
    if (selectedCollection === "latam") {
      const latamCodes = ["PE", "MX", "AR", "CL", "CO", "BR", "ES", "UY"];
      const code = (m.countryOfOrigin || m.originCountry || "").toUpperCase();
      const name = (m.originCountryName || "").toLowerCase();
      const isLatam =
        latamCodes.includes(code) ||
        m.id.startsWith("latam_") ||
        name.includes("perú") ||
        name.includes("méxico") ||
        name.includes("argentina") ||
        name.includes("colombia") ||
        name.includes("chile") ||
        name.includes("brasil") ||
        name.includes("españa") ||
        m.theatricalCountries?.some((c) => ["PE", "MX", "AR", "CL", "CO"].includes(c)) ||
        m.director?.toLowerCase().includes("cuarón") ||
        m.director?.toLowerCase().includes("iñárritu") ||
        m.director?.toLowerCase().includes("del toro") ||
        m.director?.toLowerCase().includes("campanella") ||
        m.director?.toLowerCase().includes("szifron") ||
        m.director?.toLowerCase().includes("almodóvar");
      return isLatam;
    }

    if (selectedCollection === "top250") {
      const score = calculateCompositeScore(m.ratings);
      return score >= 8.2;
    }

    if (selectedCollection === "awards") {
      const score = calculateCompositeScore(m.ratings);
      const hasAwardGenre = m.genres.some((g) =>
        ["Drama", "Historia", "Crimen", "Guerra", "Biografía"].includes(g)
      );
      return score >= 8.0 && (hasAwardGenre || m.releaseYear < 2015);
    }

    if (selectedCollection === "cult") {
      const isCultGenre = m.genres.some((g) =>
        ["Ciencia Ficción", "Terror", "Suspenso", "Misterio", "Fantasía Oscura", "Acción"].includes(g)
      );
      const score = calculateCompositeScore(m.ratings);
      return isCultGenre && score >= 7.6;
    }

    return true;
  });

  // Métricas de Progreso Personal del Cinéfilo con Metas Progresivas Alcanzables
  const watchedCount = displayedMovies.filter(
    (m) => watchedIds.has(m.id) || userRatings[m.id] != null
  ).length;

  let currentTierIndex = 0;
  for (let i = 0; i < CINEPHILE_TIERS.length; i++) {
    if (watchedCount < CINEPHILE_TIERS[i].target) {
      currentTierIndex = i;
      break;
    }
    currentTierIndex = i;
  }

  const currentTier = CINEPHILE_TIERS[currentTierIndex];
  const prevTarget = currentTierIndex > 0 ? CINEPHILE_TIERS[currentTierIndex - 1].target : 0;
  const currentTarget = currentTier.target;
  const isTierCompleted = watchedCount >= currentTarget;

  const progressPercent = isTierCompleted
    ? 100
    : Math.min(100, Math.round(((watchedCount - prevTarget) / (currentTarget - prevTarget)) * 100));

  // Handlers interactivos
  const handleToggleWatchlist = async (movie: Movie, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!currentUser) {
      onOpenAuthModal?.("login", "Inicia sesión para guardar películas en tu lista Por Ver.");
      return;
    }

    const nextSet = new Set(watchlistIds);
    if (nextSet.has(movie.id)) nextSet.delete(movie.id);
    else nextSet.add(movie.id);
    setWatchlistIds(nextSet);

    try {
      await api.toggleMovieStatus(movie, "toggle_watchlist", currentUser.id);
    } catch (err) {
      console.warn("Error toggling watchlist:", err);
    }
  };

  const handleToggleWatched = async (movie: Movie, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!currentUser) {
      onOpenAuthModal?.("login", "Inicia sesión para registrar películas como ya vistas.");
      return;
    }

    const nextSet = new Set(watchedIds);
    if (nextSet.has(movie.id)) nextSet.delete(movie.id);
    else nextSet.add(movie.id);
    setWatchedIds(nextSet);

    try {
      await api.toggleMovieStatus(movie, "toggle_watched", currentUser.id);
    } catch (err) {
      console.warn("Error toggling watched:", err);
    }
  };

  const handleQuickRate = async (movie: Movie, stars: number, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!currentUser) {
      onOpenAuthModal?.("login", "Inicia sesión para calificar películas en 1 clic.");
      return;
    }

    setUserRatings((prev) => ({ ...prev, [movie.id]: stars }));
    setWatchedIds((prev) => new Set(prev).add(movie.id));
    setActiveRatingPopover(null);
    setRatingSuccessMovie(movie.id);
    setTimeout(() => setRatingSuccessMovie(null), 2500);

    try {
      await api.submitReview({
        movieId: movie.id,
        movieTitle: movie.title,
        moviePosterUrl: movie.posterURL,
        movieReleaseYear: movie.releaseYear,
        rating: stars,
        comment: "",
        isCommunity: true,
      });
    } catch (err) {
      console.warn("Error saving quick rating:", err);
    }
  };

  return (
    <div className="w-full max-w-[1780px] mx-auto px-4 sm:px-8 lg:px-12 xl:px-16 flex flex-col gap-5 py-4 sm:py-6">
      
      {/* ============================================================== */}
      {/* 1. CABECERA COMPACTA Y MODERNA: FILMOTECA MUNDIAL               */}
      {/* ============================================================== */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-white/[0.08]">
        
        {/* Título y Badge identificador */}
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-2xl bg-amber-500/10 border border-cinema-gold/30 text-cinema-gold flex-shrink-0 shadow-[0_0_15px_rgba(229,169,60,0.12)]">
            <Globe className="w-5 h-5 sm:w-6 sm:h-6" />
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-2.5 flex-wrap">
              <h1 className="text-xl sm:text-2xl lg:text-3xl font-black text-white uppercase tracking-tight">
                Filmoteca Mundial
              </h1>
              <span className="hidden sm:inline-flex items-center px-2.5 py-0.5 rounded-full bg-amber-500/15 border border-cinema-gold/30 text-cinema-gold text-[10px] font-mono font-bold">
                TMDB & IMDb Global
              </span>
            </div>
            <p className="text-xs text-cinema-textMuted font-mono">
              {displayedMovies.length} títulos disponibles • Calificaciones oficiales y ficha técnica completa
            </p>
          </div>
        </div>

        {/* Buscador y Switch Grilla/Lista */}
        <div className="flex items-center gap-3 w-full md:w-auto">
          {/* Buscador en vivo */}
          <div className="relative flex-grow md:w-72 lg:w-96">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-cinema-gold" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Buscar título en base de datos mundial..."
              className="w-full pl-10 pr-9 py-2 rounded-xl bg-[#0D0F14] border border-white/10 focus:border-cinema-gold text-xs sm:text-sm text-white placeholder-cinema-textMuted outline-none shadow-md transition-all"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-cinema-textMuted hover:text-white"
              >
                ✕
              </button>
            )}
          </div>

          {/* Switch Grilla vs Lista */}
          <div className="flex items-center bg-[#0D0F14] border border-white/10 p-1 rounded-xl shadow-inner flex-shrink-0">
            <button
              onClick={() => setViewMode("grid")}
              title="Vista de Grilla de Posters"
              className={`p-1.5 rounded-lg transition-all ${
                viewMode === "grid"
                  ? "bg-cinema-gold text-black shadow-md font-bold"
                  : "text-cinema-textMuted hover:text-white"
              }`}
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode("list")}
              title="Vista de Lista Cinéfila con Acordeón (2 por fila)"
              className={`p-1.5 rounded-lg transition-all ${
                viewMode === "list"
                  ? "bg-cinema-gold text-black shadow-md font-bold"
                  : "text-cinema-textMuted hover:text-white"
              }`}
            >
              <List className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* ============================================================== */}
      {/* 2. SELECCIONES ESPECIALES (COLECCIONES DESTACADAS)            */}
      {/* ============================================================== */}
      <div className="flex flex-col gap-3">
        <div className="flex items-center gap-1.5 overflow-x-auto scrollbar-none py-0.5 w-full">
          <span className="text-[11px] font-mono text-cinema-gold font-bold uppercase tracking-wider mr-2 hidden sm:inline flex-shrink-0">
            Colecciones Especiales:
          </span>
          {COLLECTIONS.map((col) => {
            const Icon = col.icon;
            const isActive = selectedCollection === col.id;
            return (
              <button
                key={col.id}
                onClick={() => {
                  setSelectedCollection(col.id);
                  setSelectedDirector(null);
                }}
                className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all flex-shrink-0 ${
                  isActive
                    ? "bg-amber-500/20 text-cinema-gold border border-cinema-gold shadow-[0_0_12px_rgba(229,169,60,0.2)] font-bold scale-[1.02]"
                    : "bg-[#0D0F14] hover:bg-white/5 text-gray-300 hover:text-white border border-white/10"
                }`}
              >
                <Icon className={`w-3.5 h-3.5 ${isActive ? "text-cinema-gold" : "text-cinema-textMuted"}`} />
                <span>{col.label}</span>
              </button>
            );
          })}
        </div>

        {/* ============================================================== */}
        {/* 3. LOGICA DE NIVELES CINÉFILOS (METAS PROGRESIVAS ALCANZABLES) */}
        {/* ============================================================== */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 p-3.5 rounded-2xl bg-gradient-to-r from-amber-500/10 via-amber-950/20 to-transparent border border-cinema-gold/30 shadow-inner">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-cinema-gold/20 text-cinema-gold border border-cinema-gold/40 text-lg flex items-center justify-center">
              <span>{currentTier.badge}</span>
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-bold text-white flex items-center gap-2">
                <span>Nivel: <strong className="text-cinema-gold">{currentTier.title}</strong></span>
                <span className="font-mono text-gray-300 text-xs">
                  • {watchedCount} / {currentTarget} películas ({progressPercent}%)
                </span>
              </span>
              <span className="text-[11px] text-cinema-textMuted font-mono">
                {isTierCompleted
                  ? `¡Completaste la meta de ${currentTarget} películas! Insignia desbloqueada: ${currentTier.badge} ${currentTier.title} 🏆`
                  : `Mira ${currentTarget - watchedCount} película(s) más para alcanzar el 100% de este nivel.`}
              </span>
            </div>
          </div>

          {/* Barra medidora hacia la meta actual */}
          <div className="w-full sm:w-64 flex items-center gap-2">
            <div className="flex-grow h-2.5 rounded-full bg-black/60 border border-white/10 overflow-hidden p-0.5">
              <div
                className="h-full rounded-full bg-gradient-to-r from-amber-600 via-cinema-gold to-yellow-300 transition-all duration-500 shadow-[0_0_8px_rgba(229,169,60,0.5)]"
                style={{ width: `${progressPercent}%` }}
              />
            </div>
            <span className="text-xs font-mono font-bold text-cinema-gold w-10 text-right">
              {progressPercent}%
            </span>
          </div>
        </div>

        {/* ============================================================== */}
        {/* 4. FILTROS RÁPIDOS: PAÍS, DÉCADAS, GÉNEROS Y DIRECTOR ACTIVO   */}
        {/* ============================================================== */}
        <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-3 pt-1 border-t border-white/[0.08]">
          
          {/* Píldoras de Décadas */}
          <div className="flex items-center gap-1.5 overflow-x-auto w-full lg:w-auto scrollbar-none py-1">
            {DECADES.map((d) => (
              <button
                key={d.id}
                onClick={() => setSelectedDecade(d.id)}
                className={`px-2.5 py-1 rounded-lg text-[11px] font-semibold whitespace-nowrap transition-colors ${
                  selectedDecade === d.id
                    ? "bg-cinema-gold text-black font-bold shadow-sm"
                    : "bg-white/5 hover:bg-white/10 text-gray-300 border border-white/5"
                }`}
              >
                {d.label}
              </button>
            ))}
          </div>

          {/* Selectores agrupados: País, Género y Ordenamiento */}
          <div className="flex items-center gap-2 w-full lg:w-auto flex-wrap lg:flex-nowrap justify-between lg:justify-end flex-shrink-0">
            {/* Filtro por País */}
            <select
              value={selectedCountry}
              onChange={(e) => setSelectedCountry(e.target.value)}
              className="px-2.5 py-1.5 rounded-xl bg-[#0D0F14] border border-white/10 text-xs font-medium text-white outline-none focus:border-cinema-gold cursor-pointer"
            >
              {COUNTRIES.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.label}
                </option>
              ))}
            </select>

            {/* Selector de Género */}
            <select
              value={selectedGenre}
              onChange={(e) => setSelectedGenre(e.target.value)}
              className="px-2.5 py-1.5 rounded-xl bg-[#0D0F14] border border-white/10 text-xs font-medium text-white outline-none focus:border-cinema-gold cursor-pointer"
            >
              {GENRES.map((g) => (
                <option key={g} value={g}>
                  {g === "Todos" ? "Todos los Géneros" : g}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Badge Activo de Filtro por Director */}
        {selectedDirector && (
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-amber-500/15 border border-cinema-gold/40 text-cinema-gold text-xs font-semibold self-start animate-in fade-in">
            <span>🎬 Filtrando obras de <strong>{selectedDirector}</strong></span>
            <button
              onClick={() => setSelectedDirector(null)}
              className="p-0.5 hover:bg-cinema-gold/20 rounded-full text-cinema-gold hover:text-white"
              title="Quitar filtro de director"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {/* ============================================================== */}
        {/* CHIPS DE ORDENAMIENTO RÁPIDO EN 1 CLIC (Mejor Calificadas / Más Recientes) */}
        {/* ============================================================== */}
        <div className="flex items-center justify-between gap-3 flex-wrap pt-1 border-t border-white/[0.05]">
          <div className="flex items-center gap-1.5 flex-wrap">
            <span className="text-[11px] font-mono text-cinema-textMuted uppercase mr-1">Ordenar rápido:</span>
            
            <button
              onClick={() => setSortBy("ratingDesc")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                sortBy === "ratingDesc"
                  ? "bg-cinema-gold text-black font-bold shadow-md shadow-amber-950/40 scale-[1.02]"
                  : "bg-white/5 hover:bg-white/10 text-gray-300 border border-white/10"
              }`}
            >
              <span>★</span>
              <span>Mejor Calificadas</span>
            </button>

            <button
              onClick={() => setSortBy("yearDesc")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                sortBy === "yearDesc"
                  ? "bg-cinema-gold text-black font-bold shadow-md shadow-amber-950/40 scale-[1.02]"
                  : "bg-white/5 hover:bg-white/10 text-gray-300 border border-white/10"
              }`}
            >
              <span>📅</span>
              <span>Más Recientes</span>
            </button>

            <button
              onClick={() => setSortBy("criticsDesc")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                sortBy === "criticsDesc"
                  ? "bg-cinema-gold text-black font-bold shadow-md shadow-amber-950/40 scale-[1.02]"
                  : "bg-white/5 hover:bg-white/10 text-gray-300 border border-white/10"
              }`}
            >
              <span>🍅</span>
              <span>Tomatometer Crítica</span>
            </button>

            <button
              onClick={() => setSortBy("audienceDesc")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                sortBy === "audienceDesc"
                  ? "bg-cinema-gold text-black font-bold shadow-md shadow-amber-950/40 scale-[1.02]"
                  : "bg-white/5 hover:bg-white/10 text-gray-300 border border-white/10"
              }`}
            >
              <span>🍿</span>
              <span>Popcornmeter Público</span>
            </button>
          </div>
        </div>
      </div>

      {/* Indicador de Búsqueda Activa */}
      {isSearching && (
        <div className="flex items-center gap-2 text-cinema-gold text-xs font-mono py-1">
          <span className="w-2 h-2 rounded-full bg-cinema-gold animate-ping" />
          <span>Buscando en la base de datos mundial de TMDB e IMDb...</span>
        </div>
      )}

      {/* ============================================================== */}
      {/* 5. RESULTADOS: MODO GRILLA VS MODO LISTA CON ACORDEÓN          */}
      {/* ============================================================== */}
      {loading ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 sm:gap-6 py-4">
          {Array.from({ length: 12 }).map((_, i) => (
            <div
              key={i}
              className="aspect-[2/3] rounded-2xl bg-[#0D0F14] border border-white/10 animate-pulse"
            />
          ))}
        </div>
      ) : displayedMovies.length === 0 ? (
        <div className="p-14 text-center rounded-3xl bg-[#0D0F14]/70 border border-white/10 flex flex-col items-center justify-center gap-3 my-6">
          <Film className="w-10 h-10 text-cinema-textMuted" />
          <h3 className="text-base font-bold text-white">No se encontraron películas con esos criterios</h3>
          <p className="text-xs text-cinema-textMuted max-w-md">
            Prueba seleccionando &quot;Todos los Países&quot;, &quot;Todas las Obras&quot; o quita el filtro de director si está activo.
          </p>
          {selectedDirector && (
            <button
              onClick={() => setSelectedDirector(null)}
              className="mt-2 px-3 py-1.5 rounded-xl bg-cinema-gold text-black font-bold text-xs shadow-md"
            >
              Limpiar filtro de director
            </button>
          )}
        </div>
      ) : viewMode === "grid" ? (
        /* ============================================================== */
        /* MODO GRILLA (POSTERS VISUALES CON ACCIONES RÁPIDAS HOVER)      */
        /* ============================================================== */
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3 sm:gap-5">
          {displayedMovies.map((m) => {
            const score = calculateCompositeScore(m.ratings);
            const isInWatchlist = watchlistIds.has(m.id);
            const isWatched = watchedIds.has(m.id);
            const myRating = userRatings[m.id];
            const isRatingOpen = activeRatingPopover === m.id;
            const isSuccess = ratingSuccessMovie === m.id;
            const isImageBroken = brokenImageIds.has(m.id);

            return (
              <div
                key={m.id}
                onClick={() => onSelectMovie(m)}
                className="group relative aspect-[2/3] rounded-2xl overflow-hidden bg-[#0D0F14] border border-white/10 hover:border-cinema-gold/70 shadow-lg hover:shadow-2xl hover:shadow-amber-950/30 transition-all duration-300 transform hover:-translate-y-1.5 cursor-pointer flex flex-col justify-between p-3 select-none"
              >
                {/* Poster Imagen o Fallback de Imagen No Disponible */}
                {isImageBroken ? (
                  <div className="absolute inset-0 flex flex-col items-center justify-center bg-[#111318] p-3 text-center border border-white/10 z-0">
                    <Film className="w-9 h-9 text-cinema-gold/40 mb-2" />
                    <span className="text-[10px] font-mono uppercase tracking-wider text-gray-400 font-bold leading-tight">
                      IMAGEN NO DISPONIBLE
                    </span>
                  </div>
                ) : (
                  <img
                    src={m.posterURL}
                    alt={m.title}
                    loading="lazy"
                    onError={() => {
                      setBrokenImageIds((prev) => new Set(prev).add(m.id));
                    }}
                    className="absolute inset-0 w-full h-full object-cover filter brightness-95 group-hover:brightness-105 group-hover:scale-105 transition-all duration-500"
                  />
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-black/95 via-black/25 to-black/30 pointer-events-none" />

                {/* Badges Superiores (Rating + Estados activos) */}
                <div className="relative z-10 flex items-center justify-between w-full">
                  {/* Estados activos (Ya vista / Por ver) */}
                  <div className="flex items-center gap-1">
                    {isInWatchlist && (
                      <span
                        title="Guardada en tu lista Por Ver"
                        className="p-1 rounded-lg bg-amber-500 text-black shadow-md"
                      >
                        <Bookmark className="w-3 h-3 fill-current" />
                      </span>
                    )}
                    {isWatched && (
                      <span
                        title="Ya la viste"
                        className="p-1 rounded-lg bg-emerald-500 text-black shadow-md"
                      >
                        <Eye className="w-3 h-3 fill-current" />
                      </span>
                    )}
                    {myRating && (
                      <span
                        title={`Tu calificación: ${myRating.toFixed(1)} ★`}
                        className="px-1.5 py-0.5 rounded-lg bg-cinema-gold text-black text-[10px] font-mono font-bold shadow-md"
                      >
                        {myRating}★
                      </span>
                    )}
                  </div>

                  {/* Rating Oficial */}
                  <div className="px-2 py-0.5 rounded-lg bg-black/85 border border-cinema-gold/50 text-cinema-gold font-mono font-bold text-[11px] backdrop-blur-md shadow flex items-center gap-1">
                    <span>★</span>
                    <span>{score > 0 ? score.toFixed(1) : "N/A"}</span>
                  </div>
                </div>

                {/* Toast Animado de Calificación Rápida Exitosa */}
                {isSuccess && (
                  <div className="relative z-30 mx-auto px-3 py-1 rounded-xl bg-emerald-500 text-black font-black text-xs shadow-2xl flex items-center gap-1 animate-bounce">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    <span>¡Calificada!</span>
                  </div>
                )}

                {/* OVERLAY DE ACCIONES RÁPIDAS AL PASAR EL MOUSE (LETTERBOXD STYLE) */}
                <div className="absolute inset-0 z-20 flex flex-col justify-center items-center gap-2 p-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black/65 backdrop-blur-[2px]">
                  
                  {/* Botones de 1-Clic: Por ver / Ya vista / Calificar */}
                  <div className="flex items-center gap-1.5 bg-black/80 p-1.5 rounded-2xl border border-white/20 shadow-2xl">
                    <button
                      onClick={(e) => handleToggleWatchlist(m, e)}
                      title={isInWatchlist ? "Quitar de Por Ver" : "Agregar a Por Ver (Watchlist)"}
                      className={`p-2 rounded-xl transition-all ${
                        isInWatchlist
                          ? "bg-cinema-gold text-black font-bold shadow-lg"
                          : "text-white/80 hover:text-white hover:bg-white/10"
                      }`}
                    >
                      <Bookmark className={`w-4 h-4 ${isInWatchlist ? "fill-current" : ""}`} />
                    </button>

                    <button
                      onClick={(e) => handleToggleWatched(m, e)}
                      title={isWatched ? "Marcar como no vista" : "Marcar como Ya vista"}
                      className={`p-2 rounded-xl transition-all ${
                        isWatched
                          ? "bg-emerald-500 text-black font-bold shadow-lg"
                          : "text-white/80 hover:text-white hover:bg-white/10"
                      }`}
                    >
                      <Eye className={`w-4 h-4 ${isWatched ? "fill-current" : ""}`} />
                    </button>

                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setActiveRatingPopover(isRatingOpen ? null : m.id);
                      }}
                      title="Calificar rápidamente (1 a 5 estrellas)"
                      className={`p-2 rounded-xl transition-all ${
                        myRating
                          ? "bg-amber-400 text-black font-bold shadow-lg"
                          : "text-white/80 hover:text-white hover:bg-white/10"
                      }`}
                    >
                      <Star className={`w-4 h-4 ${myRating ? "fill-current" : ""}`} />
                    </button>
                  </div>

                  {/* Popover de Estrellas 1-Clic */}
                  {isRatingOpen && (
                    <div
                      onClick={(e) => e.stopPropagation()}
                      className="flex items-center gap-1 bg-black/95 p-2 rounded-2xl border border-cinema-gold/60 shadow-2xl animate-in fade-in zoom-in-95 duration-150"
                    >
                      {[1, 2, 3, 4, 5].map((star) => (
                        <button
                          key={star}
                          onClick={(e) => handleQuickRate(m, star, e)}
                          className="p-1 hover:scale-125 transition-transform text-white/40 hover:text-cinema-gold"
                          title={`Calificar con ${star} estrellas`}
                        >
                          <Star className="w-4 h-4 fill-current hover:text-cinema-gold" />
                        </button>
                      ))}
                    </div>
                  )}

                  {/* Botón Principal: Ver Ficha Completa */}
                  <button
                    onClick={() => onSelectMovie(m)}
                    className="px-3.5 py-1.5 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black font-black text-xs shadow-xl flex items-center gap-1.5 transition-transform hover:scale-105"
                  >
                    <Clapperboard className="w-3.5 h-3.5" />
                    <span>Ver Ficha</span>
                  </button>
                </div>

                {/* Info Inferior de la Tarjeta */}
                <div className="relative z-10 flex flex-col leading-tight mt-auto">
                  <span className="text-xs sm:text-sm font-bold text-white line-clamp-1 group-hover:text-cinema-gold transition-colors">
                    {m.title}
                  </span>
                  <div className="flex items-center gap-1.5 text-[11px] text-cinema-textMuted font-mono mt-0.5">
                    <span>{m.releaseYear}</span>
                    {m.director && (
                      <>
                        <span>•</span>
                        <span
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedDirector(m.director || null);
                          }}
                          className="truncate max-w-[120px] hover:text-cinema-gold hover:underline cursor-pointer"
                          title={`Filtrar por obras de ${m.director}`}
                        >
                          {m.director}
                        </span>
                      </>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* ============================================================== */
        /* MODO LISTA CON ACORDEÓN: EXACTAMENTE 2 POR FILA                */
        /* ============================================================== */
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 sm:gap-5">
          {displayedMovies.map((m) => {
            const score = calculateCompositeScore(m.ratings);
            const critics = m.ratings.rottenTomatoesCritics ?? (score > 0 ? Math.min(100, Math.round(score * 10)) : null);
            const audience = m.ratings.rottenTomatoesAudience ?? (score > 0 ? Math.min(100, Math.round(score * 10 + 2)) : null);
            const imdb = m.ratings.imdbScore ?? (score > 0 ? parseFloat(score.toFixed(1)) : null);

            const isInWatchlist = watchlistIds.has(m.id);
            const isWatched = watchedIds.has(m.id);
            const myRating = userRatings[m.id];
            const isRatingOpen = activeRatingPopover === m.id;
            const isSuccess = ratingSuccessMovie === m.id;
            const isImageBroken = brokenImageIds.has(m.id);
            return (
              <div
                key={m.id}
                onClick={() => onSelectMovie(m)}
                className="group relative flex flex-col sm:flex-row items-start gap-4 p-4 rounded-2xl bg-[#0D0F14]/90 border border-white/10 hover:border-cinema-gold/60 hover:bg-[#12151B] transition-all duration-200 shadow-xl select-none cursor-pointer"
              >
                {/* Poster Thumbnail o Imagen No Disponible */}
                  <div className="relative w-24 sm:w-28 aspect-[2/3] rounded-xl overflow-hidden flex-shrink-0 bg-black/60 border border-white/10 group-hover:border-cinema-gold/50 shadow-lg">
                    {isImageBroken ? (
                      <div className="absolute inset-0 flex flex-col items-center justify-center bg-[#111318] p-2 text-center">
                        <Film className="w-7 h-7 text-cinema-gold/40 mb-1" />
                        <span className="text-[9px] font-mono uppercase tracking-wider text-gray-400 font-bold leading-tight">
                          IMAGEN NO DISPONIBLE
                        </span>
                      </div>
                    ) : (
                      <img
                        src={m.posterURL}
                        alt={m.title}
                        loading="lazy"
                        onError={() => {
                          setBrokenImageIds((prev) => new Set(prev).add(m.id));
                        }}
                        className="w-full h-full object-cover filter brightness-95 group-hover:scale-105 transition-transform duration-300"
                      />
                    )}
                    {isInWatchlist && (
                      <span className="absolute top-1.5 left-1.5 p-1 rounded-md bg-amber-500 text-black shadow-md">
                        <Bookmark className="w-3 h-3 fill-current" />
                      </span>
                    )}
                    {isWatched && (
                      <span className="absolute bottom-1.5 left-1.5 p-1 rounded-md bg-emerald-500 text-black shadow-md">
                        <Eye className="w-3 h-3 fill-current" />
                      </span>
                    )}
                  </div>

                  {/* Contenido Central y Puntuaciones */}
                  <div className="flex flex-col justify-between flex-grow min-w-0 h-full gap-2">
                    <div className="flex flex-col gap-1">
                      {/* Título y Año */}
                      <div className="flex items-center justify-between gap-2">
                        <h3 className="text-base font-bold text-white group-hover:text-cinema-gold transition-colors truncate">
                          {m.title}
                        </h3>
                        <span className="text-xs text-cinema-textMuted font-mono flex-shrink-0">
                          {m.releaseYear}
                        </span>
                      </div>

                      <div className="flex items-center gap-2 text-xs text-cinema-textSecondary font-mono flex-wrap">
                        {m.director && (
                          <span
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedDirector(m.director || null);
                            }}
                            className="hover:text-cinema-gold hover:underline cursor-pointer"
                            title={`Filtrar por obras de ${m.director}`}
                          >
                            Dir. {m.director}
                          </span>
                        )}
                        {m.originCountryName && (
                          <>
                            <span>•</span>
                            <span>{m.originCountryName}</span>
                          </>
                        )}
                        {Boolean(m.runtimeMinutes && m.runtimeMinutes > 0) && (
                          <>
                            <span>•</span>
                            <span>{m.runtimeMinutes} min</span>
                          </>
                        )}
                      </div>

                      {/* Géneros */}
                      <div className="flex items-center gap-1.5 flex-wrap pt-0.5">
                        {m.genres.slice(0, 3).map((g) => (
                          <span
                            key={g}
                            className="px-2 py-0.5 rounded-md bg-white/5 border border-white/10 text-[10px] text-gray-300 font-mono"
                          >
                            {g}
                          </span>
                        ))}
                      </div>

                      {/* Sinopsis corta */}
                      {m.overview && (
                        <p className="text-xs text-cinema-textMuted line-clamp-2 font-normal leading-relaxed pt-0.5">
                          {m.overview}
                        </p>
                      )}
                    </div>

                    {/* BLOQUE DE PUNTUACIONES DESTACADAS (GRANDES Y CLARAS) */}
                    <div className="grid grid-cols-4 gap-1.5 py-1.5 border-t border-b border-white/[0.08] my-0.5">
                      <div
                        title="Rating Oficial de la Industria"
                        className="flex flex-col items-center justify-center py-1 rounded-lg bg-amber-500/15 border border-cinema-gold/40 text-cinema-gold"
                      >
                        <span className="text-[9px] font-mono uppercase font-bold tracking-wider opacity-80">Oficial</span>
                        <span className="text-sm font-mono font-black text-white">
                          ★ {score > 0 ? score.toFixed(1) : "N/A"}
                        </span>
                      </div>

                      <div
                        title="Rotten Tomatoes Crítica"
                        className="flex flex-col items-center justify-center py-1 rounded-lg bg-red-950/40 border border-red-500/30 text-red-300"
                      >
                        <span className="text-[9px] font-mono uppercase font-bold tracking-wider opacity-80">🍅 Crítica</span>
                        <span className="text-sm font-mono font-black text-white">
                          {critics != null ? `${critics}%` : "-"}
                        </span>
                      </div>

                      <div
                        title="Rotten Tomatoes Audiencia"
                        className="flex flex-col items-center justify-center py-1 rounded-lg bg-amber-950/40 border border-amber-600/30 text-amber-300"
                      >
                        <span className="text-[9px] font-mono uppercase font-bold tracking-wider opacity-80">🍿 Público</span>
                        <span className="text-sm font-mono font-black text-white">
                          {audience != null ? `${audience}%` : "-"}
                        </span>
                      </div>

                      <div
                        title="Calificación IMDb"
                        className="flex flex-col items-center justify-center py-1 rounded-lg bg-[#181405] border border-cinema-imdb/40 text-cinema-imdb"
                      >
                        <span className="text-[9px] font-mono uppercase font-bold tracking-wider opacity-80">IMDb</span>
                        <span className="text-sm font-mono font-black text-white">
                          {imdb != null ? imdb.toFixed(1) : "-"}
                        </span>
                      </div>
                    </div>

                    {/* Acciones Rápidas */}
                    <div
                      onClick={(e) => e.stopPropagation()}
                      className="flex items-center justify-between gap-2 pt-1"
                    >
                      {/* Botones Por Ver / Ya vista */}
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <button
                          onClick={(e) => handleToggleWatchlist(m, e)}
                          title={isInWatchlist ? "Quitar de Por Ver" : "Agregar a Por Ver"}
                          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-xl text-xs font-semibold transition-all border ${
                            isInWatchlist
                              ? "bg-amber-500/20 text-cinema-gold border-cinema-gold font-bold"
                              : "bg-white/5 hover:bg-white/10 text-gray-300 border-white/10"
                          }`}
                        >
                          <Bookmark className={`w-3.5 h-3.5 ${isInWatchlist ? "fill-current" : ""}`} />
                          <span>{isInWatchlist ? "En Por Ver" : "Por ver"}</span>
                        </button>

                        <button
                          onClick={(e) => handleToggleWatched(m, e)}
                          title={isWatched ? "Marcar como no vista" : "Marcar como Ya vista"}
                          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-xl text-xs font-semibold transition-all border ${
                            isWatched
                              ? "bg-emerald-500/20 text-emerald-400 border-emerald-500 font-bold"
                              : "bg-white/5 hover:bg-white/10 text-gray-300 border-white/10"
                          }`}
                        >
                          <Eye className={`w-3.5 h-3.5 ${isWatched ? "fill-current" : ""}`} />
                          <span>{isWatched ? "Vista" : "Ya vista"}</span>
                        </button>

                        {/* Calificar 1-clic */}
                        <div className="relative">
                          <button
                            onClick={() => setActiveRatingPopover(isRatingOpen ? null : m.id)}
                            className={`flex items-center gap-1 px-2.5 py-1.5 rounded-xl text-xs font-semibold transition-all border ${
                              myRating
                                ? "bg-amber-500/20 text-cinema-gold border-cinema-gold font-bold"
                                : "bg-white/5 hover:bg-white/10 text-gray-300 border-white/10"
                            }`}
                            title="Calificar película"
                          >
                            <Star className={`w-3.5 h-3.5 ${myRating ? "fill-current text-cinema-gold" : ""}`} />
                            <span>{myRating ? `${myRating}★` : "Calificar"}</span>
                          </button>

                          {isRatingOpen && (
                            <div className="absolute left-0 bottom-full mb-2 z-30 flex items-center gap-1 bg-black/95 p-2 rounded-2xl border border-cinema-gold/60 shadow-2xl animate-in fade-in zoom-in-95">
                              {[1, 2, 3, 4, 5].map((star) => (
                                <button
                                  key={star}
                                  onClick={(e) => handleQuickRate(m, star, e)}
                                  className="p-1 hover:scale-125 transition-transform text-white/40 hover:text-cinema-gold"
                                  title={`${star} estrellas`}
                                >
                                  <Star className="w-4 h-4 fill-current hover:text-cinema-gold" />
                                </button>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Botón de Ficha Completa */}
                      <div className="flex items-center gap-1.5">
                        {isSuccess && (
                          <span className="text-xs font-mono font-bold text-emerald-400 flex items-center gap-1 animate-pulse">
                            <Check className="w-3.5 h-3.5" /> Calificada
                          </span>
                        )}

                        <button
                          onClick={() => onSelectMovie(m)}
                          className="px-3.5 py-1.5 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black font-black text-xs shadow-md flex items-center gap-1.5 transition-transform hover:scale-105"
                        >
                          <Clapperboard className="w-3.5 h-3.5" />
                          <span>Ver Ficha</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
            );
          })}
        </div>
      )}

      {/* ============================================================== */}
      {/* 6. BOTÓN CARGAR MÁS PELÍCULAS (+20)                            */}
      {/* ============================================================== */}
      {displayedMovies.length > 0 && hasMore && (
        <div className="flex justify-center pt-4 pb-8">
          <button
            onClick={handleLoadMore}
            disabled={isLoadingMore}
            className="flex items-center gap-2.5 px-6 py-3 rounded-full bg-[#0D0F14] hover:bg-white/5 border border-cinema-gold/40 hover:border-cinema-gold text-cinema-gold hover:text-amber-300 font-bold text-sm shadow-[0_0_20px_rgba(229,169,60,0.12)] transition-all hover:scale-105 disabled:opacity-50"
          >
            {isLoadingMore ? (
              <>
                <span className="w-4 h-4 border-2 border-cinema-gold border-t-transparent rounded-full animate-spin" />
                <span>Cargando más obras mundiales...</span>
              </>
            ) : (
              <>
                <Plus className="w-4 h-4" />
                <span>Cargar 20 películas más</span>
              </>
            )}
          </button>
        </div>
      )}

    </div>
  );
};
