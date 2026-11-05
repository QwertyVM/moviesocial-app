"use client";

import React, { useState, useEffect } from 'react';
import { Movie, Review, User } from '../../types';
import { RatingBadges } from '../common/RatingBadges';
import { AddReviewModal } from './AddReviewModal';
import { api } from '../../services/api';
import {
  X,
  MapPin,
  Clock,
  Calendar,
  Share2,
  Edit3,
  ThumbsUp,
  MessageCircle,
  HelpCircle,
  Sparkles,
  Ticket,
} from 'lucide-react';

interface MovieDetailModalProps {
  movie: Movie | null;
  isOpen: boolean;
  onClose: () => void;
  currentUser: User;
  onShareInChat?: (movie: Movie) => void;
}

export const MovieDetailModal: React.FC<MovieDetailModalProps> = ({
  movie,
  isOpen,
  onClose,
  currentUser,
  onShareInChat,
}) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [isReviewModalOpen, setIsReviewModalOpen] = useState(false);

  useEffect(() => {
    if (movie) {
      api.getReviews(movie.id).then(setReviews);
    }
  }, [movie]);

  if (!isOpen || !movie) return null;

  const friendsReviews = reviews.filter((r) => !r.isCommunity && r.userId !== currentUser.id);
  const communityReviews = reviews.filter((r) => r.isCommunity || r.userId === currentUser.id);

  const friendsAvg =
    friendsReviews.length > 0
      ? friendsReviews.reduce((sum, r) => sum + r.rating, 0) / friendsReviews.length
      : undefined;

  const showtimes = movie.showtimes || [];

  const handleReviewSubmitted = async (data: any) => {
    const newRev = await api.submitReview(data);
    setReviews([newRev, ...reviews]);
    return newRev;
  };

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-black/85 backdrop-blur-md overflow-y-auto">
        <div className="relative w-full max-w-4xl my-auto rounded-3xl bg-cinema-bg border border-cinema-border shadow-2xl overflow-hidden flex flex-col max-h-[92vh]">
          {/* Backdrop Header */}
          <div className="relative h-64 sm:h-80 w-full overflow-hidden flex-shrink-0">
            <img
              src={movie.backdropURL || movie.posterURL}
              alt={movie.title}
              className="w-full h-full object-cover object-center filter brightness-60"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-cinema-bg via-cinema-bg/60 to-transparent" />

            {/* Close button */}
            <button
              onClick={onClose}
              className="absolute top-4 right-4 z-10 p-2.5 rounded-full bg-black/60 hover:bg-black/90 text-white/80 hover:text-white border border-cinema-border backdrop-blur-md transition-transform hover:scale-110"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Floating Quick Action Buttons */}
            <div className="absolute bottom-4 right-4 z-10 flex items-center gap-2">
              {onShareInChat && (
                <button
                  onClick={() => onShareInChat(movie)}
                  className="px-3.5 py-2 rounded-xl bg-cinema-surface/90 hover:bg-cinema-card border border-cinema-border text-white text-xs font-semibold flex items-center gap-2 backdrop-blur-md transition-colors"
                >
                  <Share2 className="w-3.5 h-3.5 text-cinema-gold" />
                  <span>Compartir</span>
                </button>
              )}
              <button
                onClick={() => setIsReviewModalOpen(true)}
                className="px-4 py-2 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold flex items-center gap-2 shadow-lg shadow-amber-900/40 transition-transform hover:scale-105"
              >
                <Edit3 className="w-3.5 h-3.5" />
                <span>Calificar</span>
              </button>
            </div>

            {/* Overlay Info Header */}
            <div className="absolute bottom-4 left-4 sm:left-8 right-36 flex items-end gap-4">
              <div className="flex flex-col gap-1.5">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="px-2.5 py-0.5 rounded-md bg-cinema-gold/20 text-cinema-gold border border-cinema-gold/40 text-xs font-mono font-bold">
                    {movie.releaseYear}
                  </span>
                  <span className="text-xs text-cinema-textSecondary flex items-center gap-1 font-mono">
                    <Clock className="w-3 h-3 text-cinema-textMuted" />
                    {movie.runtimeMinutes} min
                  </span>
                  {movie.director && (
                    <span className="text-xs text-cinema-textSecondary">
                      Dir. <strong className="text-white">{movie.director}</strong>
                    </span>
                  )}
                  {movie.originCountryName && (
                    <span className="text-xs text-cinema-textMuted">
                      ({movie.originCountryName})
                    </span>
                  )}
                </div>
                <h1 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight leading-tight">
                  {movie.title}
                </h1>
              </div>
            </div>
          </div>

          {/* Modal Body (Scrollable) */}
          <div className="p-4 sm:p-8 overflow-y-auto flex flex-col gap-8">
            {/* 1. Ratings Row */}
            <div className="p-4 rounded-2xl bg-cinema-surface border border-cinema-border flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-semibold text-cinema-textSecondary uppercase tracking-wider">
                    MovieScore Oficial
                  </span>
                  <span
                    className="cursor-help text-cinema-textMuted"
                    title="Cruce ponderado oficial: 50% IMDb + 30% Rotten Tomatoes Críticos + 20% Audiencia"
                  >
                    <HelpCircle className="w-3.5 h-3.5" />
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-3xl font-extrabold font-mono text-cinema-gold">
                    {movie.ratings.compositeScore?.toFixed(1) || 'N/A'}
                  </span>
                  <span className="text-xs text-cinema-textMuted leading-tight max-w-[140px]">
                    Cruce ponderado sobre 10
                  </span>
                </div>
              </div>

              <div className="flex-grow flex justify-end">
                <RatingBadges ratings={movie.ratings} friendsRating={friendsAvg} size="lg" />
              </div>
            </div>

            {/* 2. Overview */}
            <div className="flex flex-col gap-2">
              <h2 className="text-xs font-bold text-cinema-textSecondary uppercase tracking-wider">
                Sinopsis
              </h2>
              <p className="text-sm sm:text-base text-gray-300 leading-relaxed font-normal">
                {movie.overview}
              </p>
              <div className="flex flex-wrap gap-2 mt-1">
                {movie.genres.map((g) => (
                  <span
                    key={g}
                    className="px-2.5 py-1 rounded-lg bg-cinema-card text-cinema-textSecondary border border-cinema-border text-xs font-medium"
                  >
                    {g}
                  </span>
                ))}
              </div>
            </div>

            {/* 3. Local Showtimes (Cartelera) */}
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-cinema-gold" />
                  <h2 className="text-sm font-bold text-white uppercase tracking-wider">
                    Funciones y Cines en {currentUser.location.city}
                  </h2>
                </div>
                <span className="text-xs text-cinema-textMuted font-mono">
                  {currentUser.location.flagEmoji} {currentUser.location.area || currentUser.location.city}
                </span>
              </div>

              {showtimes.length > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {showtimes.map((s, idx) => (
                    <div
                      key={idx}
                      className="p-3.5 rounded-xl bg-cinema-card border border-cinema-border hover:border-cinema-gold/40 transition-colors flex flex-col gap-2"
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-semibold text-xs text-white flex items-center gap-1.5">
                          <Ticket className="w-3.5 h-3.5 text-cinema-gold" />
                          {s.cinemaName}
                        </span>
                        <span className="text-[10px] px-2 py-0.5 rounded bg-cinema-surface border border-cinema-border text-cinema-textMuted font-mono">
                          {s.roomFormat}
                        </span>
                      </div>
                      <div className="flex flex-wrap gap-2 pt-1">
                        {s.times.map((t) => (
                          <span
                            key={t}
                            className="px-2.5 py-1 rounded-md bg-cinema-surface text-cinema-gold font-mono font-bold text-xs border border-cinema-border hover:border-cinema-gold/50 cursor-pointer transition-colors"
                          >
                            {t}
                          </span>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="p-4 rounded-xl bg-cinema-card/50 border border-cinema-border text-center text-xs text-cinema-textMuted">
                  {movie.releaseYear < 2024
                    ? 'Esta película pertenece al catálogo de obras maestras históricas. Puedes consultarla o debatirla en Cineclubs.'
                    : `No hay funciones físicas programadas hoy en los cines registrados de ${currentUser.location.city}. Consulta en otras ciudades desde el selector de ciudad.`}
                </div>
              )}
            </div>

            {/* 4. Friends Reviews Section */}
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between border-b border-cinema-border pb-2">
                <div className="flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-purple-400" />
                  <h2 className="text-sm font-bold text-white uppercase tracking-wider">
                    Qué opinan tus amigos ({friendsReviews.length})
                  </h2>
                </div>
                {friendsAvg && (
                  <span className="text-xs font-semibold text-purple-300">
                    Promedio Amigos: {friendsAvg.toFixed(1)}★
                  </span>
                )}
              </div>

              {friendsReviews.length > 0 ? (
                <div className="flex flex-col gap-3">
                  {friendsReviews.map((r) => (
                    <div
                      key={r.id}
                      className="p-4 rounded-xl bg-cinema-card border border-cinema-border flex flex-col gap-2"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2.5">
                          <img
                            src={r.userAvatarUrl}
                            alt={r.userName}
                            className="w-7 h-7 rounded-full object-cover border border-purple-500/40"
                          />
                          <span className="text-xs font-semibold text-white">{r.userName}</span>
                        </div>
                        <span className="text-xs font-bold font-mono text-cinema-gold">
                          {r.rating.toFixed(1)} / 5.0 ★
                        </span>
                      </div>
                      <p className="text-xs sm:text-sm text-gray-300">{r.comment}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-cinema-textMuted italic py-2">
                  Ninguno de tus amigos ha escrito una reseña todavía para esta película. ¡Sé el primero en opinar!
                </p>
              )}
            </div>

            {/* 5. Community Reviews */}
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between border-b border-cinema-border pb-2">
                <h2 className="text-sm font-bold text-cinema-textSecondary uppercase tracking-wider">
                  Críticas de la Comunidad ({communityReviews.length})
                </h2>
              </div>

              {communityReviews.length > 0 ? (
                <div className="flex flex-col gap-3">
                  {communityReviews.map((r) => (
                    <div
                      key={r.id}
                      className="p-4 rounded-xl bg-cinema-card/70 border border-cinema-border flex flex-col gap-2"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2.5">
                          <img
                            src={r.userAvatarUrl}
                            alt={r.userName}
                            className="w-6 h-6 rounded-full object-cover"
                          />
                          <span className="text-xs font-semibold text-white">{r.userName}</span>
                        </div>
                        <span className="text-xs font-mono font-semibold text-cinema-gold">
                          {r.rating.toFixed(1)} ★
                        </span>
                      </div>
                      <p className="text-xs sm:text-sm text-gray-300">{r.comment}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-cinema-textMuted italic py-1">
                  Aún no hay críticas públicas registradas.
                </p>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Add Review Sub-modal */}
      <AddReviewModal
        movie={movie}
        isOpen={isReviewModalOpen}
        onClose={() => setIsReviewModalOpen(false)}
        onSubmit={handleReviewSubmitted}
      />
    </>
  );
};

