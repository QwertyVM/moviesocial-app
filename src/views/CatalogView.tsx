"use client";

import React, { useState, useEffect } from 'react';
import { Movie, User } from '../types';
import { MovieCard } from '../components/movies/MovieCard';
import { api } from '../services/api';
import { Film, Sparkles, Search, SlidersHorizontal, MapPin } from 'lucide-react';

interface CatalogViewProps {
  currentUser: User;
  onSelectMovie: (movie: Movie) => void;
  initialCategory?: 'nowPlaying' | 'classics';
}

export const CatalogView: React.FC<CatalogViewProps> = ({
  currentUser,
  onSelectMovie,
  initialCategory = 'nowPlaying',
}) => {
  const [category, setCategory] = useState<'nowPlaying' | 'classics'>(initialCategory);
  const [decade, setDecade] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [movies, setMovies] = useState<Movie[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    if (initialCategory) {
      setCategory(initialCategory);
    }
  }, [initialCategory]);

  const loadMovies = async () => {
    setLoading(true);
    const data = await api.getMovies({
      category,
      city: currentUser.location.city,
      decade,
      searchQuery,
    });
    setMovies(data);
    setLoading(false);
  };

  useEffect(() => {
    loadMovies();
  }, [category, decade, searchQuery, currentUser.location.city]);

  const decadesList = [
    { id: 'all', label: 'Todas las Épocas' },
    { id: '2010s', label: '2010s' },
    { id: '2000s', label: '2000s' },
    { id: '90s', label: '90s' },
    { id: '80s', label: '80s' },
    { id: '70s', label: '70s' },
    { id: '60s', label: '≤ 60s' },
  ];

  const inTheatersCount = movies.filter((m) => m.isInTheatersLocally).length;

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
            {category === 'nowPlaying' && (
              <span className="text-xs text-cinema-textMuted flex items-center gap-1">
                <MapPin className="w-3 h-3 text-cinema-gold" />
                {currentUser.location.city} ({inTheatersCount} en cartelera)
              </span>
            )}
          </div>
          <h1 className="text-xl sm:text-2xl font-extrabold text-white tracking-tight">
            {category === 'nowPlaying'
              ? `Cartelera & Estrenos en ${currentUser.location.city}`
              : 'Clásicos de la Historia por Cruce de Ratings'}
          </h1>
          <p className="text-xs text-cinema-textSecondary max-w-2xl">
            {category === 'nowPlaying'
              ? `Salas, horarios y disponibilidad física en cines de ${currentUser.location.city} combinados con ratings oficiales de Rotten Tomatoes e IMDb.`
              : 'Obras maestras de toda la historia ordenadas matemáticamente por el MovieScore (50% IMDb + 30% RT Críticos + 20% Audiencia).'}
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
            <span>Cartelera Local</span>
          </button>
          <button
            onClick={() => setCategory('classics')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              category === 'classics'
                ? 'bg-cinema-card text-cinema-gold shadow-md border border-cinema-border'
                : 'text-cinema-textSecondary hover:text-white'
            }`}
          >
            <Sparkles className="w-4 h-4" />
            <span>Clásicos Históricos</span>
          </button>
        </div>
      </div>

      {/* Controls Bar: Search & Decade Filters */}
      <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
        {/* Search Input */}
        <div className="relative flex-grow max-w-md">
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

        {/* Decade Filters (Only shown in Classics mode) */}
        {category === 'classics' && (
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 scrollbar-none">
            <SlidersHorizontal className="w-3.5 h-3.5 text-cinema-textMuted mr-1 flex-shrink-0 hidden sm:inline" />
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
              userCity={currentUser.location.city}
            />
          ))}
        </div>
      ) : (
        <div className="p-12 text-center rounded-3xl bg-cinema-card border border-cinema-border flex flex-col items-center justify-center gap-3">
          <Film className="w-10 h-10 text-cinema-textMuted" />
          <p className="text-sm font-semibold text-white">No se encontraron películas</p>
          <p className="text-xs text-cinema-textMuted max-w-sm">
            Prueba ajustando tu búsqueda o cambiando los filtros de época o la ciudad seleccionada.
          </p>
        </div>
      )}
    </div>
  );
};
