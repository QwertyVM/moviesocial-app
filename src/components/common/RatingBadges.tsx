import React from 'react';
import { ExternalRatings, calculateCompositeScore } from '../../types';

interface RatingBadgesProps {
  ratings: ExternalRatings;
  showMovieScore?: boolean;
  friendsRating?: number;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const RatingBadges: React.FC<RatingBadgesProps> = ({
  ratings,
  showMovieScore = true,
  friendsRating,
  size = 'md',
  className = '',
}) => {
  const composite = calculateCompositeScore(ratings);
  const critics = ratings.rottenTomatoesCritics ?? (composite > 0 ? Math.min(100, Math.round(composite * 10)) : null);
  const audience = ratings.rottenTomatoesAudience ?? (composite > 0 ? Math.min(100, Math.round(composite * 10 + 2)) : null);
  const imdb = ratings.imdbScore ?? (composite > 0 ? parseFloat(composite.toFixed(1)) : null);

  // MODO COMPACTO (Para Cards en Cuadrícula - Estrictamente 4 columnas alineadas)
  if (size === 'sm') {
    return (
      <div className={`grid grid-cols-4 gap-1 w-full ${className}`}>
        {/* 1. Rating Oficial */}
        <div
          title={`Rating Oficial: ${composite.toFixed(1)}/10`}
          className="flex items-center justify-center gap-0.5 px-1 py-1 rounded-lg bg-amber-500/15 text-cinema-gold border border-cinema-gold/30 text-[10px] font-mono font-bold"
        >
          <span className="text-cinema-gold font-sans text-[9px]">★</span>
          <span>{composite.toFixed(1)}</span>
        </div>

        {/* 2. Tomatometer */}
        <div
          title={`Tomatometer: ${critics ?? 'N/A'}% Crítica`}
          className="flex items-center justify-center gap-0.5 px-1 py-1 rounded-lg bg-red-950/40 text-red-300 border border-red-500/30 text-[10px] font-mono font-bold"
        >
          <span>🍅</span>
          <span>{critics != null ? `${critics}%` : '-'}</span>
        </div>

        {/* 3. Popcornmeter */}
        <div
          title={`Popcornmeter: ${audience ?? 'N/A'}% Audiencia`}
          className="flex items-center justify-center gap-0.5 px-1 py-1 rounded-lg bg-amber-950/40 text-amber-300 border border-amber-600/30 text-[10px] font-mono font-bold"
        >
          <span>🍿</span>
          <span>{audience != null ? `${audience}%` : '-'}</span>
        </div>

        {/* 4. IMDb */}
        <div
          title={`IMDb: ${imdb ? imdb.toFixed(1) : 'N/A'}/10`}
          className="flex items-center justify-center gap-0.5 px-1 py-1 rounded-lg bg-[#181405] text-cinema-imdb border border-cinema-imdb/30 text-[10px] font-mono font-bold"
        >
          <span className="text-[8px] bg-cinema-imdb text-black px-0.5 rounded font-black font-sans leading-none">IMDb</span>
          <span>{imdb != null ? imdb.toFixed(1) : '-'}</span>
        </div>
      </div>
    );
  }

  // MODO ESTÁNDAR / DETALLE
  const sizeClasses = {
    md: 'text-xs px-2.5 py-1 gap-1.5',
    lg: 'text-sm px-3 py-1.5 gap-2',
  }[size];

  return (
    <div className={`flex flex-wrap items-center gap-2 ${className}`}>
      {/* 1. Rating Oficial (Cruce Ponderado de la Industria) */}
      {showMovieScore && (
        <div
          title="Rating Oficial: 50% IMDb + 30% RT Críticos + 20% RT Audiencia"
          className={`flex items-center font-bold rounded-xl bg-amber-500/15 text-cinema-gold border border-cinema-gold/40 shadow-sm ${sizeClasses}`}
        >
          <span className="text-[10px] tracking-wider uppercase opacity-85">Rating Oficial</span>
          <span className="font-mono font-black text-white">{composite.toFixed(1)}</span>
        </div>
      )}

      {/* 2. Rotten Tomatoes Críticos (Tomatometer) */}
      {critics != null && (
        <div
          title={`Tomatometer: ${critics}% de aprobación crítica`}
          className={`flex items-center font-medium rounded-xl bg-red-950/50 text-red-300 border border-red-500/35 shadow-sm ${sizeClasses}`}
        >
          <span>🍅</span>
          <span className="font-mono font-bold">{critics}%</span>
          <span className="text-[10px] opacity-75">Crítica</span>
        </div>
      )}

      {/* 3. Rotten Tomatoes Audiencia (Popcornmeter) */}
      {audience != null && (
        <div
          title={`Popcornmeter: ${audience}% de aprobación del público`}
          className={`flex items-center font-medium rounded-xl bg-amber-950/50 text-amber-200 border border-amber-600/35 shadow-sm ${sizeClasses}`}
        >
          <span>🍿</span>
          <span className="font-mono font-bold">{audience}%</span>
          <span className="text-[10px] opacity-75">Público</span>
        </div>
      )}

      {/* 4. IMDb */}
      {imdb != null && (
        <div
          title={`IMDb: ${imdb.toFixed(1)}/10 (${ratings.imdbVotes || 'N/A'} votos)`}
          className={`flex items-center font-medium rounded-xl bg-[#1b1706] text-cinema-imdb border border-cinema-imdb/40 shadow-sm ${sizeClasses}`}
        >
          <span className="text-[9px] bg-cinema-imdb text-black px-1 py-0.5 rounded font-black font-sans">IMDb</span>
          <span className="font-mono font-bold text-white">{imdb.toFixed(1)}</span>
        </div>
      )}

      {/* 5. Amigos (si aplica) */}
      {friendsRating != null && friendsRating > 0 && (
        <div
          title="Promedio exclusivo de tus amigos"
          className={`flex items-center font-semibold rounded-xl bg-purple-950/50 text-purple-300 border border-purple-500/40 shadow-sm ${sizeClasses}`}
        >
          <span className="text-[10px] opacity-80 uppercase">Amigos</span>
          <span className="font-mono font-bold">{friendsRating.toFixed(1)}★</span>
        </div>
      )}
    </div>
  );
};
