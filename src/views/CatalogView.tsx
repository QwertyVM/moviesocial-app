"use client";

import React, { useState, useEffect } from 'react';
import { Movie, User, UserLocation } from '../types';
import { MovieCard } from '../components/movies/MovieCard';
import { api } from '../services/api';
import {
  Film,
  Sparkles,
  Search,
  SlidersHorizontal,
  MapPin,
  Star,
  Calendar,
  Layers,
  ArrowDownWideNarrow,
  Check,
} from 'lucide-react';

interface CatalogViewProps {
  currentUser?: User | null;
  location?: UserLocation;
  onSelectMovie: (movie: Movie) => void;
  initialCategory?: 'nowPlaying' | 'classics' | 'catalog';
}

export const CatalogView: React.FC<CatalogViewProps> = ({
  currentUser,
  location,
  onSelectMovie,
  initialCategory = 'nowPlaying',
}) => {
  const activeLocation =
    location ||
    currentUser?.location || {
      city: 'Lima',
      country: 'Perú',
      countryCode: 'PE',
      flagEmoji: '🇵🇪',
      isLocal: true,
      area: 'Lima',
    };

  const [category, setCategory] = useState<'nowPlaying' | 'catalog'>(
    initialCategory === 'classics' || initialCategory === 'catalog' ? 'catalog' : 'nowPlaying'
  );

  // Filtros del catálogo
  const [decade, setDecade] = useState<string>('all');
  const [genre, setGenre] = useState<string>('all');
  const [minRating, setMinRating] = useState<number | null>(null);
  const [sortBy, setSortBy] = useState<'yearDesc' | 'ratingDesc' | 'criticsDesc' | 'audienceDesc'>('yearDesc');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const [movies, setMovies] = useState<Movie[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    if (initialCategory === 'classics' || initialCategory === 'catalog') {
      setCategory('catalog');
    } else if (initialCategory === 'nowPlaying') {
      setCategory('nowPlaying');
    }

    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      const q = params.get('q');
      if (q) {
        setSearchQuery(q);
      }
    }
  }, [initialCategory]);

  const loadMovies = async () => {
    setLoading(true);
    const data = await api.getMovies({
      category,
      city: activeLocation.city,
      countryCode: activeLocation.countryCode,
      decade,
      minRating,
      genre,
      sortBy: category === 'nowPlaying' ? 'ratingDesc' : sortBy,
      searchQuery,
    });
    setMovies(data);
    setLoading(false);
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      loadMovies();
    }, searchQuery ? 250 : 0);
    return () => clearTimeout(timer);
  }, [category, decade, minRating, genre, sortBy, searchQuery, activeLocation.countryCode, activeLocation.city]);

  const genresList = [
    { id: 'all', label: 'Todos los Géneros' },
    { id: 'Acción', label: 'Acción' },
    { id: 'Drama', label: 'Drama' },
    { id: 'Crimen', label: 'Crimen' },
    { id: 'Ciencia Ficción', label: 'Ciencia Ficción' },
    { id: 'Terror', label: 'Terror' },
    { id: 'Suspenso', label: 'Suspenso' },
    { id: 'Aventura', label: 'Aventura' },
    { id: 'Animación', label: 'Animación' },
    { id: 'Comedia', label: 'Comedia' },
    { id: 'Romance', label: 'Romance' },
  ];

  const ratingOptions = [
    { value: null, label: 'Cualquier Rating' },
    { value: 9.0, label: '★ 9.0+ Obras Maestras' },
    { value: 8.0, label: '★ 8.0+ Excelentes' },
    { value: 7.0, label: '★ 7.0+ Muy Buenas' },
    { value: 6.0, label: '★ 6.0+ Aceptables' },
  ];

  const decadesList = [
    { id: 'all', label: 'Todas las Épocas' },
    { id: '2020s', label: '2020s' },
    { id: '2010s', label: '2010s' },
    { id: '2000s', label: '2000s' },
    { id: '90s', label: '90s' },
    { id: '80s', label: '80s' },
    { id: '70s', label: '70s' },
    { id: '60s', label: '≤ 60s' },
  ];

  const sortOptions = [
    { id: 'yearDesc', label: '📅 Más recientes primero (Año desc)' },
    { id: 'ratingDesc', label: '⭐ Mayor MovieScore' },
    { id: 'criticsDesc', label: '🍅 Mayor Aprobación Crítica (RT)' },
    { id: 'audienceDesc', label: '🍿 Favoritas del Público (RT)' },
  ];

  return (
    <div className="flex flex-col gap-6 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      {/* Top Banner & Mode Switcher */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-cinema-card p-4 sm:p-6 rounded-3xl border border-cinema-border shadow-xl">
        <div className="flex flex-col gap-1.5">
          <div className="flex items-center gap-2">
            <span className="px-2.5 py-0.5 rounded-full bg-cinema-gold/15 text-cinema-gold text-xs font-semibold border border-cinema-gold/30 flex items-center gap-1">
              <Sparkles className="w-3 h-3" />
              Descubrimiento Cinéfilo
            </span>
            {category === 'nowPlaying' ? (
              <span className="text-xs text-cinema-textMuted flex items-center gap-1" suppressHydrationWarning>
                <MapPin className="w-3 h-3 text-cinema-gold" />
                {activeLocation.city} ({activeLocation.countryCode}) • {movies.length} en cartelera hoy
              </span>
            ) : (
              <span className="text-xs text-cinema-textMuted flex items-center gap-1">
                <Calendar className="w-3 h-3 text-cinema-gold" />
                Catálogo general ({movies.length} títulos)
              </span>
            )}
          </div>
          <h1 className="text-xl sm:text-2xl font-extrabold text-white tracking-tight" suppressHydrationWarning>
            {category === 'nowPlaying'
              ? `Películas en Estreno en ${activeLocation.country || activeLocation.city}`
              : 'Catálogo de Películas (Fuera de Estreno)'}
          </h1>
          <p className="text-xs text-cinema-textSecondary max-w-2xl" suppressHydrationWarning>
            {category === 'nowPlaying'
              ? `Títulos que se están emitiendo actualmente en los cines según tu ubicación en ${activeLocation.country || activeLocation.city}.`
              : 'Películas fuera de salas ordenadas desde la más actual hasta la más antigua, con filtros de rating, género y épocas.'}
          </p>
        </div>

        {/* Segmented Switcher */}
        <div className="flex items-center bg-cinema-surface p-1 rounded-2xl border border-cinema-border flex-shrink-0">
          <button
            onClick={() => setCategory('nowPlaying')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              category === 'nowPlaying'
                ? 'bg-cinema-card text-cinema-gold shadow-md border border-cinema-border'
                : 'text-cinema-textSecondary hover:text-white'
            }`}
          >
            <Film className="w-4 h-4" />
            <span suppressHydrationWarning>En Estreno ({activeLocation.countryCode})</span>
          </button>
          <button
            onClick={() => setCategory('catalog')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              category === 'catalog'
                ? 'bg-cinema-card text-cinema-gold shadow-md border border-cinema-border'
                : 'text-cinema-textSecondary hover:text-white'
            }`}
          >
            <Layers className="w-4 h-4" />
            <span>Catálogo Completo</span>
          </button>
        </div>
      </div>

      {/* Controls Bar: Search & Advanced Filters */}
      <div className="flex flex-col gap-3">
        <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-3">
          {/* Search Input */}
          <div className="relative flex-grow max-w-lg">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-cinema-textMuted" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Buscar por título, director, género o año..."
              className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-cinema-card border border-cinema-border focus:border-cinema-gold focus:ring-1 focus:ring-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none transition-colors"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-cinema-textMuted hover:text-white"
              >
                ✕
              </button>
            )}
          </div>

          {/* Quick Selectors in Catalog Mode */}
          {category === 'catalog' && (
            <div className="flex flex-wrap items-center gap-2">
              {/* Sort By Dropdown */}
              <div className="flex items-center gap-1.5 bg-cinema-card px-3 py-2 rounded-xl border border-cinema-border">
                <ArrowDownWideNarrow className="w-3.5 h-3.5 text-cinema-gold" />
                <span className="text-[11px] text-cinema-textMuted">Orden:</span>
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as any)}
                  className="bg-transparent text-xs text-white outline-none cursor-pointer font-medium"
                >
                  {sortOptions.map((opt) => (
                    <option key={opt.id} value={opt.id} className="bg-cinema-card text-white">
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Min Rating Dropdown */}
              <div className="flex items-center gap-1.5 bg-cinema-card px-3 py-2 rounded-xl border border-cinema-border">
                <Star className="w-3.5 h-3.5 text-amber-400" />
                <span className="text-[11px] text-cinema-textMuted">Rating:</span>
                <select
                  value={minRating === null ? '' : minRating.toString()}
                  onChange={(e) => setMinRating(e.target.value ? parseFloat(e.target.value) : null)}
                  className="bg-transparent text-xs text-white outline-none cursor-pointer font-medium"
                >
                  {ratingOptions.map((opt, idx) => (
                    <option
                      key={idx}
                      value={opt.value === null ? '' : opt.value.toString()}
                      className="bg-cinema-card text-white"
                    >
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Genre Dropdown */}
              <div className="flex items-center gap-1.5 bg-cinema-card px-3 py-2 rounded-xl border border-cinema-border">
                <SlidersHorizontal className="w-3.5 h-3.5 text-cinema-gold" />
                <span className="text-[11px] text-cinema-textMuted">Género:</span>
                <select
                  value={genre}
                  onChange={(e) => setGenre(e.target.value)}
                  className="bg-transparent text-xs text-white outline-none cursor-pointer font-medium"
                >
                  {genresList.map((g) => (
                    <option key={g.id} value={g.id} className="bg-cinema-card text-white">
                      {g.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          )}
        </div>

        {/* Decade Filters Bar (Only shown in Catalog mode) */}
        {category === 'catalog' && (
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none pt-1">
            <span className="text-[11px] text-cinema-textMuted mr-1 flex-shrink-0 font-medium">
              Década:
            </span>
            {decadesList.map((d) => (
              <button
                key={d.id}
                onClick={() => setDecade(d.id)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap transition-all ${
                  decade === d.id
                    ? 'bg-cinema-gold text-black font-bold shadow'
                    : 'bg-cinema-card text-cinema-textSecondary hover:text-white border border-cinema-border'
                }`}
              >
                {d.label}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Movies Grid */}
      {loading ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {[...Array(10)].map((_, i) => (
            <div
              key={i}
              className="aspect-[2/3] rounded-2xl bg-cinema-card border border-cinema-border animate-pulse"
            />
          ))}
        </div>
      ) : movies.length > 0 ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {movies.map((m) => (
            <MovieCard
              key={m.id}
              movie={m}
              onSelectMovie={onSelectMovie}
              userCity={activeLocation.city}
            />
          ))}
        </div>
      ) : (
        <div className="p-12 text-center rounded-3xl bg-cinema-card border border-cinema-border flex flex-col items-center justify-center gap-3">
          <Film className="w-10 h-10 text-cinema-textMuted" />
          <p className="text-sm font-semibold text-white">No se encontraron películas</p>
          <p className="text-xs text-cinema-textMuted max-w-sm">
            {category === 'nowPlaying'
              ? `No hay películas en cartelera registradas actualmente para ${activeLocation.country || activeLocation.city}. Prueba seleccionando otro país en el selector superior.`
              : 'Prueba ajustando los filtros de rating, época o género.'}
          </p>
          {(decade !== 'all' || genre !== 'all' || minRating !== null || searchQuery) && (
            <button
              onClick={() => {
                setDecade('all');
                setGenre('all');
                setMinRating(null);
                setSearchQuery('');
              }}
              className="px-4 py-2 rounded-xl bg-cinema-surface hover:bg-cinema-border border border-cinema-border text-xs text-cinema-gold font-semibold transition-colors"
            >
              Restablecer filtros
            </button>
          )}
        </div>
      )}
    </div>
  );
};
