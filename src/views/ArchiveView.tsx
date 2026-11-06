"use client";

import React, { useState, useEffect } from "react";
import { Movie, User, UserLocation, calculateCompositeScore } from "../types";
import { api } from "../services/api";
import {
  Globe,
  Search,
  Film,
  Sparkles,
  Filter,
  SlidersHorizontal,
  Star,
  Clapperboard,
} from "lucide-react";

interface ArchiveViewProps {
  currentUser?: User | null;
  location?: UserLocation;
  onSelectMovie: (movie: Movie) => void;
  onOpenAuthModal?: (mode: "login" | "register", reason?: string) => void;
}

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

export const ArchiveView: React.FC<ArchiveViewProps> = ({
  currentUser,
  location,
  onSelectMovie,
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

  const [searchQuery, setSearchQuery] = useState("");
  const [selectedDecade, setSelectedDecade] = useState("all");
  const [selectedGenre, setSelectedGenre] = useState("Todos");
  const [sortBy, setSortBy] = useState<"ratingDesc" | "yearDesc" | "criticsDesc" | "audienceDesc">("ratingDesc");

  const [movies, setMovies] = useState<Movie[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSearching, setIsSearching] = useState(false);

  // Cargar catálogo curado o buscar reactivamente
  const fetchArchive = async (queryText: string) => {
    if (queryText.trim()) {
      setIsSearching(true);
      try {
        const res = await fetch(
          `/api/movies/catalog?q=${encodeURIComponent(queryText.trim())}&country=${activeLocation.countryCode}`
        );
        if (res.ok) {
          const data = await res.json();
          setMovies(data.movies || []);
        }
      } catch (err) {
        console.warn("Error buscando en archivo mundial:", err);
      } finally {
        setIsSearching(false);
        setLoading(false);
      }
    } else {
      setLoading(true);
      try {
        const list = await api.getMovies({
          category: "catalog",
          decade: selectedDecade,
          genre: selectedGenre === "Todos" ? "all" : selectedGenre,
          sortBy,
          countryCode: activeLocation.countryCode,
        });
        setMovies(list);
      } catch (err) {
        console.warn("Error cargando archivo general:", err);
      } finally {
        setLoading(false);
      }
    }
  };

  // Debounced search trigger
  useEffect(() => {
    const timer = setTimeout(() => {
      fetchArchive(searchQuery);
    }, 320);
    return () => clearTimeout(timer);
  }, [searchQuery, selectedDecade, selectedGenre, sortBy, activeLocation.countryCode]);

  return (
    <div className="w-full max-w-[1780px] mx-auto px-4 sm:px-8 lg:px-12 xl:px-16 flex flex-col gap-8 py-6 sm:py-8">
      
      {/* ============================================================== */}
      {/* 1. CABECERA PROTAGÓNICA: ARCHIVO MUNDIAL (LETTERBOXD / MUBI)   */}
      {/* ============================================================== */}
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-6 pb-6 border-b border-cinema-border/70">
        <div className="flex flex-col gap-2 max-w-3xl">
          <div className="flex items-center gap-2.5">
            <div className="p-2.5 rounded-2xl bg-amber-500/10 border border-cinema-gold/40 text-cinema-gold">
              <Globe className="w-6 h-6" />
            </div>
            <div>
              <span className="text-[11px] font-mono uppercase tracking-widest text-cinema-gold font-bold">
                Filmoteca Internacional
              </span>
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white uppercase tracking-tight">
                Archivo Mundial de Cine
              </h1>
            </div>
          </div>
          <p className="text-sm sm:text-base text-gray-300 leading-relaxed font-normal">
            Explora la base de datos cinematográfica global de TMDB e IMDb. Consulta cualquier obra, sus directores, elenco completo, metraje oficial y fichas técnicas cinefílicas.
          </p>
        </div>

        {/* BUSCADOR PROMINENTE HORIZONTAL */}
        <div className="relative w-full lg:w-[480px] xl:w-[560px]">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-cinema-gold" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Escribe el título de cualquier película mundial..."
            className="w-full pl-12 pr-10 py-3.5 rounded-2xl bg-cinema-card border border-cinema-border focus:border-cinema-gold text-sm sm:text-base text-white placeholder-cinema-textMuted outline-none shadow-xl transition-all"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery("")}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-cinema-textMuted hover:text-white"
            >
              ✕
            </button>
          )}
        </div>
      </div>

      {/* ============================================================== */}
      {/* 2. BARRA DE FILTROS Y ORDENAMIENTO (RÁPIDA Y CÓMODA)          */}
      {/* ============================================================== */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 py-2 border-b border-cinema-border/40">
        
        {/* Filtros por Década */}
        <div className="flex items-center gap-1.5 overflow-x-auto w-full md:w-auto scrollbar-none py-1">
          {DECADES.map((d) => (
            <button
              key={d.id}
              onClick={() => setSelectedDecade(d.id)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-colors ${
                selectedDecade === d.id
                  ? "bg-cinema-gold text-black font-bold shadow-md shadow-amber-900/30"
                  : "bg-cinema-card hover:bg-cinema-surface text-cinema-textSecondary hover:text-white border border-cinema-border"
              }`}
            >
              {d.label}
            </button>
          ))}
        </div>

        {/* Ordenamiento */}
        <div className="flex items-center gap-2 self-end md:self-auto flex-shrink-0">
          <span className="text-xs text-cinema-textMuted font-mono hidden sm:inline">Ordenar:</span>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as any)}
            className="px-3 py-1.5 rounded-xl bg-cinema-card border border-cinema-border text-xs font-semibold text-white outline-none focus:border-cinema-gold cursor-pointer"
          >
            <option value="ratingDesc">Mayor MovieScore ★</option>
            <option value="yearDesc">Más Recientes</option>
            <option value="criticsDesc">Tomatometer Crítica 🍅</option>
            <option value="audienceDesc">Popcornmeter Audiencia 🍿</option>
          </select>
        </div>
      </div>

      {/* Filtros por Género */}
      <div className="flex items-center gap-1.5 overflow-x-auto scrollbar-none py-1">
        {GENRES.map((g) => (
          <button
            key={g}
            onClick={() => setSelectedGenre(g)}
            className={`px-3 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-colors ${
              selectedGenre === g
                ? "bg-white/20 text-cinema-gold font-bold border border-cinema-gold/50"
                : "bg-white/5 hover:bg-white/10 text-gray-300 border border-white/10"
            }`}
          >
            {g}
          </button>
        ))}
      </div>

      {/* ============================================================== */}
      {/* 3. GRILLA DE PELÍCULAS DEL ARCHIVO MUNDIAL (HASTA 6 COLS 1080P) */}
      {/* ============================================================== */}
      {isSearching && (
        <div className="flex items-center gap-2 text-cinema-gold text-xs font-mono py-2">
          <span className="w-2.5 h-2.5 rounded-full bg-cinema-gold animate-ping" />
          <span>Buscando en la base de datos mundial de TMDB e IMDb...</span>
        </div>
      )}

      {loading ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 sm:gap-6 py-6">
          {Array.from({ length: 12 }).map((_, i) => (
            <div
              key={i}
              className="aspect-[2/3] rounded-2xl bg-cinema-card border border-cinema-border animate-pulse"
            />
          ))}
        </div>
      ) : movies.length === 0 ? (
        <div className="p-16 text-center rounded-3xl bg-cinema-card/50 border border-cinema-border flex flex-col items-center justify-center gap-3 my-8">
          <Film className="w-10 h-10 text-cinema-textMuted" />
          <h3 className="text-base font-bold text-white">No se encontraron películas con esos criterios</h3>
          <p className="text-xs text-cinema-textMuted max-w-md">
            Intenta escribir el título con otra ortografía o selecciona &quot;Todas las épocas&quot; y &quot;Todos los géneros&quot;.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 sm:gap-6">
          {movies.map((m) => {
            const score = calculateCompositeScore(m.ratings);
            return (
              <div
                key={m.id}
                onClick={() => onSelectMovie(m)}
                className="group relative aspect-[2/3] rounded-2xl overflow-hidden bg-cinema-card border border-cinema-border hover:border-cinema-gold/70 shadow-lg hover:shadow-2xl hover:shadow-amber-950/30 transition-all duration-300 transform hover:-translate-y-1.5 cursor-pointer flex flex-col justify-end p-3"
              >
                <img
                  src={m.posterURL}
                  alt={m.title}
                  loading="lazy"
                  className="absolute inset-0 w-full h-full object-cover filter brightness-95 group-hover:brightness-105 group-hover:scale-105 transition-all duration-500"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/25 to-transparent pointer-events-none" />

                {/* Badge de Puntuación Superior */}
                <div className="absolute top-2.5 right-2.5 z-10 px-2 py-0.5 rounded-lg bg-black/80 border border-cinema-gold/40 text-cinema-gold font-mono font-bold text-[11px] backdrop-blur-md shadow flex items-center gap-1">
                  <span>★</span>
                  <span>{score > 0 ? score.toFixed(1) : "N/A"}</span>
                </div>

                {/* Hover Action Badge */}
                <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black/40 backdrop-blur-[1px] pointer-events-none">
                  <span className="px-3.5 py-1.5 rounded-xl bg-cinema-gold text-black font-black text-xs shadow-xl flex items-center gap-1.5">
                    <Clapperboard className="w-3.5 h-3.5" />
                    <span>Ver Ficha</span>
                  </span>
                </div>

                {/* Info Inferior */}
                <div className="relative z-10 flex flex-col leading-tight">
                  <span className="text-xs sm:text-sm font-bold text-white line-clamp-1 group-hover:text-cinema-gold transition-colors">
                    {m.title}
                  </span>
                  <div className="flex items-center gap-1.5 text-[11px] text-cinema-textMuted font-mono mt-0.5">
                    <span>{m.releaseYear}</span>
                    {m.director && (
                      <>
                        <span>•</span>
                        <span className="truncate">{m.director}</span>
                      </>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

    </div>
  );
};
