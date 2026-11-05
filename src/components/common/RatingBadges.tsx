import React from 'react';
import { ExternalRatings, calculateCompositeScore } from '../../types';
import { Star, Flame, Popcorn } from 'lucide-react';

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

  const sizeClasses = {
    sm: 'text-xs px-2 py-0.5 gap-1',
    md: 'text-xs px-2.5 py-1 gap-1.5',
    lg: 'text-sm px-3 py-1.5 gap-2',
  }[size];

  return (
    <div className={`flex flex-wrap items-center gap-2 ${className}`}>
      {/* 1. MovieScore (Cruce Ponderado MovieSocial) */}
      {showMovieScore && (
        <div
          title="MovieScore: 50% IMDb + 30% RT Críticos + 20% RT Audiencia"
          className={`flex items-center font-bold rounded-md bg-cinema-gold/15 text-cinema-gold border border-cinema-gold/30 ${sizeClasses}`}
        >
          <span className="text-[10px] tracking-wider uppercase opacity-80">Score</span>
          <span className="font-mono font-extrabold text-white">{composite.toFixed(1)}</span>
        </div>
      )}

      {/* 2. Rotten Tomatoes Críticos (Tomatometer) */}
      {ratings.rottenTomatoesCritics != null && (
        <div
          title={`Tomatometer: ${ratings.rottenTomatoesCritics}% de aprobación crítica`}
          className={`flex items-center font-medium rounded-md bg-red-950/40 text-red-400 border border-red-500/25 ${sizeClasses}`}
        >
          <Flame className="w-3.5 h-3.5 text-cinema-red fill-cinema-red" />
          <span>{ratings.rottenTomatoesCritics}%</span>
        </div>
      )}

      {/* 3. Rotten Tomatoes Audiencia (Popcornmeter) */}
      {ratings.rottenTomatoesAudience != null && (
        <div
          title={`Popcornmeter: ${ratings.rottenTomatoesAudience}% de aprobación del público`}
          className={`flex items-center font-medium rounded-md bg-emerald-950/40 text-emerald-400 border border-emerald-500/25 ${sizeClasses}`}
        >
          <Popcorn className="w-3.5 h-3.5 text-cinema-green" />
          <span>{ratings.rottenTomatoesAudience}%</span>
        </div>
      )}

      {/* 4. IMDb */}
      {ratings.imdbScore != null && (
        <div
          title={`IMDb: ${ratings.imdbScore}/10 (${ratings.imdbVotes || 'N/A'} votos)`}
          className={`flex items-center font-medium rounded-md bg-amber-950/40 text-cinema-imdb border border-cinema-imdb/25 ${sizeClasses}`}
        >
          <Star className="w-3.5 h-3.5 fill-cinema-imdb text-cinema-imdb" />
          <span className="font-mono font-semibold">{ratings.imdbScore.toFixed(1)}</span>
        </div>
      )}

      {/* 5. Amigos (si aplica) */}
      {friendsRating != null && friendsRating > 0 && (
        <div
          title="Promedio exclusivo de tus amigos"
          className={`flex items-center font-semibold rounded-md bg-purple-950/40 text-purple-300 border border-purple-500/30 ${sizeClasses}`}
        >
          <span className="text-[10px] opacity-80 uppercase">Amigos</span>
          <span className="font-mono">{friendsRating.toFixed(1)}★</span>
        </div>
      )}
    </div>
  );
};

