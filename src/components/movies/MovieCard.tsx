import React from 'react';
import { Movie } from '../../types';
import { RatingBadges } from '../common/RatingBadges';
import { Film, Clock } from 'lucide-react';

interface MovieCardProps {
  movie: Movie;
  onSelectMovie: (movie: Movie) => void;
  userCity: string;
  lens?: 'friends' | 'global';
  friendsRating?: number | null;
}

export const MovieCard: React.FC<MovieCardProps> = ({
  movie,
  onSelectMovie,
}) => {
  return (
    <div
      onClick={() => onSelectMovie(movie)}
      className="group relative flex flex-col rounded-2xl bg-cinema-card border border-cinema-border hover:border-cinema-gold/60 transition-all duration-300 hover:shadow-2xl hover:shadow-black/90 hover:-translate-y-1.5 cursor-pointer overflow-hidden"
    >
      {/* Contenedor del Afiche (Limpio, Nítido, sin elementos superpuestos que tapen el arte) */}
      <div className="relative aspect-[2/3] w-full bg-cinema-surface overflow-hidden">
        <img
          src={movie.posterURL}
          alt={movie.title}
          loading="lazy"
          className="w-full h-full object-cover transition-transform duration-500 ease-out group-hover:scale-105"
          onError={(e) => {
            (e.currentTarget as HTMLImageElement).src =
              'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500';
          }}
        />

        {/* Degradado sutil de iluminación en el borde inferior */}
        <div className="absolute inset-0 bg-gradient-to-t from-cinema-card/80 via-transparent to-transparent opacity-80" />

        {/* Hover Action Pill */}
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black/50 backdrop-blur-[2px] z-20">
          <span className="px-4 py-2 rounded-full bg-cinema-gold hover:bg-amber-400 text-black font-extrabold text-xs tracking-wide shadow-2xl transform translate-y-2 group-hover:translate-y-0 transition-transform duration-300 flex items-center gap-2">
            <Film className="w-3.5 h-3.5" />
            Explorar Ficha
          </span>
        </div>
      </div>

      {/* Contenedor de Información (Orden Visual Estricto: Título -> Metadatos -> Matriz de 4 Scores) */}
      <div className="p-3 sm:p-3.5 flex flex-col flex-grow justify-between gap-2.5 bg-cinema-card">
        <div className="flex flex-col gap-1">
          {/* Fila 1: Título y Año */}
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-bold text-sm text-white line-clamp-1 group-hover:text-cinema-gold transition-colors">
              {movie.title}
            </h3>
            <span className="text-xs text-cinema-textMuted font-mono flex-shrink-0">
              {movie.releaseYear}
            </span>
          </div>

          {/* Fila 2: Género y Tiempo de Duración */}
          <div className="flex items-center gap-1.5 text-[11px] text-cinema-textSecondary">
            <span className="truncate max-w-[130px]">{movie.genres.slice(0, 2).join(' / ')}</span>
            {movie.runtimeMinutes && (
              <>
                <span className="text-cinema-textMuted">•</span>
                <span className="flex items-center gap-1 text-cinema-gold font-mono font-medium flex-shrink-0">
                  <Clock className="w-3 h-3 text-cinema-gold" />
                  {Math.floor(movie.runtimeMinutes / 60)}h {movie.runtimeMinutes % 60}m
                </span>
              </>
            )}
          </div>
        </div>

        {/* Fila 3: Matriz de 4 Calificaciones Alineadas en Cuadrícula (Sin desbordes ni saltos irregulares) */}
        <div className="pt-2 border-t border-cinema-border/50">
          <RatingBadges ratings={movie.ratings} showMovieScore={true} size="sm" />
        </div>
      </div>
    </div>
  );
};
