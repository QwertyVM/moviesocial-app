import React from 'react';
import { Movie } from '../../types';
import { RatingBadges } from '../common/RatingBadges';
import { MapPin, Film } from 'lucide-react';

interface MovieCardProps {
  movie: Movie;
  onSelectMovie: (movie: Movie) => void;
  userCity: string;
}

export const MovieCard: React.FC<MovieCardProps> = ({ movie, onSelectMovie, userCity }) => {
  const isInTheaters = Boolean(movie.isInTheatersLocally);

  return (
    <div
      onClick={() => onSelectMovie(movie)}
      className="group relative flex flex-col rounded-2xl bg-cinema-card border border-cinema-border hover:border-cinema-gold/50 transition-all duration-300 hover:shadow-2xl hover:shadow-black/80 hover:-translate-y-1.5 cursor-pointer overflow-hidden"
    >
      {/* Poster Container */}
      <div className="relative aspect-[2/3] w-full bg-cinema-surface overflow-hidden">
        <img
          src={movie.posterURL}
          alt={movie.title}
          loading="lazy"
          className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          onError={(e) => {
            (e.currentTarget as HTMLImageElement).src =
              'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500';
          }}
        />

        {/* Gradient Overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-cinema-card via-transparent to-black/60 opacity-80 group-hover:opacity-60 transition-opacity" />

        {/* Top Badges */}
        <div className="absolute top-2.5 left-2.5 right-2.5 flex items-center justify-between gap-1.5 pointer-events-none">
          {/* MovieScore Pill */}
          {movie.ratings.compositeScore != null && (
            <div className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-black/80 backdrop-blur-md border border-cinema-gold/40 text-cinema-gold font-mono font-bold text-xs shadow-lg">
              <span className="text-[9px] uppercase tracking-wider text-cinema-textMuted">Score</span>
              <span>{movie.ratings.compositeScore.toFixed(1)}</span>
            </div>
          )}

          {/* Theatrical Release Pill */}
          {isInTheaters ? (
            <div
              className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-emerald-950/90 backdrop-blur-md border border-emerald-500/40 text-emerald-300 font-semibold text-[10px] shadow-lg animate-pulse"
              title={`En cartelera de cines actualmente`}
            >
              <Film className="w-2.5 h-2.5 text-emerald-400" />
              <span>En Estreno</span>
            </div>
          ) : (
            <div
              className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-zinc-900/80 backdrop-blur-md border border-zinc-700/40 text-zinc-400 font-medium text-[10px] shadow"
            >
              <span>Catálogo</span>
            </div>
          )}
        </div>

        {/* Hover Action Pill */}
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/40 backdrop-blur-[2px]">
          <span className="px-4 py-2 rounded-full bg-cinema-gold text-black font-semibold text-xs tracking-wide shadow-xl transform translate-y-2 group-hover:translate-y-0 transition-transform flex items-center gap-1.5">
            <Film className="w-3.5 h-3.5" />
            Ver Ficha y Calificaciones
          </span>
        </div>
      </div>

      {/* Info Container */}
      <div className="p-3.5 flex flex-col flex-grow justify-between gap-2">
        <div>
          <div className="flex items-baseline justify-between gap-2">
            <h3 className="font-bold text-sm text-white line-clamp-1 group-hover:text-cinema-gold transition-colors">
              {movie.title}
            </h3>
            <span className="text-xs text-cinema-textMuted font-mono flex-shrink-0">
              {movie.releaseYear}
            </span>
          </div>

          <p className="text-[11px] text-cinema-textSecondary mt-0.5 line-clamp-1">
            {movie.genres.join(' • ')}
          </p>
        </div>

        {/* Ratings Badges Bar */}
        <div className="pt-2 border-t border-cinema-border/60">
          <RatingBadges ratings={movie.ratings} showMovieScore={false} size="sm" />
        </div>
      </div>
    </div>
  );
};

