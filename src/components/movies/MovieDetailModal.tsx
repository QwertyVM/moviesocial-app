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
  Film,
  Globe,
} from 'lucide-react';

interface MovieDetailModalProps {
  movie: Movie | null;
  isOpen: boolean;
  onClose: () => void;
  currentUser: User;
  onShareInChat?: (movie: Movie) => void;
  onOpenSubscriptionModal?: (reason?: string) => void;
}

export const MovieDetailModal: React.FC<MovieDetailModalProps> = ({
  movie,
  isOpen,
  onClose,
  currentUser,
  onShareInChat,
  onOpenSubscriptionModal,
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
              onError={(e) => {
                (e.currentTarget as HTMLImageElement).src =
                  'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1280';
              }}
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
                  {movie.imdbId && (
                    <a
                      href={`https://www.imdb.com/title/${movie.imdbId}/`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="ml-2 px-2 py-0.5 rounded bg-cinema-card border border-cinema-imdb/40 text-cinema-imdb hover:bg-amber-950/40 text-[11px] font-bold tracking-wide transition-colors flex items-center gap-1"
                      title="Ver ficha oficial en IMDb"
                    >
                      <span>IMDb</span>
                      <span className="text-[10px]">↗</span>
                    </a>
                  )}
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

            {/* 3. Estado de Estreno / Exhibición */}
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Film className="w-4 h-4 text-cinema-gold" />
                  <h2 className="text-sm font-bold text-white uppercase tracking-wider">
                    Estado de Estreno en {currentUser.location.country || currentUser.location.city}
                  </h2>
                </div>
                <span className="text-xs text-cinema-textMuted font-mono">
                  {currentUser.location.flagEmoji} {currentUser.location.city} ({currentUser.location.countryCode})
                </span>
              </div>

              <div className="p-4 rounded-2xl bg-cinema-card border border-cinema-border flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div className="flex items-start gap-3">
                  <div
                    className={`p-2.5 rounded-xl border ${
                      movie.isInTheatersLocally
                        ? 'bg-emerald-950/60 border-emerald-500/50 text-emerald-400'
                        : 'bg-zinc-900 border-zinc-700 text-zinc-400'
                    }`}
                  >
                    <Film className="w-6 h-6" />
                  </div>
                  <div className="flex flex-col gap-1">
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-sm font-bold ${
                          movie.isInTheatersLocally ? 'text-emerald-400' : 'text-zinc-300'
                        }`}
                      >
                        {movie.isInTheatersLocally
                          ? 'En Estreno Comercial en Cines'
                          : 'Fuera de Estreno / Catálogo General'}
                      </span>
                      {movie.isInTheatersLocally && (
                        <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 text-[10px] font-bold border border-emerald-500/30">
                          En Cartelera Hoy
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-cinema-textSecondary max-w-xl">
                      {movie.isInTheatersLocally
                        ? `Esta película se encuentra en sus primeras 2 semanas de estreno en salas de cine de ${currentUser.location.country || currentUser.location.city}.`
                        : `Esta película ya superó su ventana de estreno inicial (más de 2 semanas en salas) y forma parte del catálogo general.`}
                    </p>

                    {movie.isInTheatersLocally && movie.theatersPlaying && movie.theatersPlaying.length > 0 && (
                      <div className="flex flex-wrap items-center gap-1.5 pt-1.5">
                        <span className="text-[10px] text-cinema-textMuted uppercase font-mono mr-1">
                          Cadenas ({currentUser.location.countryCode}):
                        </span>
                        {movie.theatersPlaying.map((chain) => (
                          <span
                            key={chain}
                            className="px-2 py-0.5 rounded-md bg-cinema-surface border border-cinema-border text-cinema-gold text-[10px] font-semibold"
                          >
                            {chain}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

                <div className="flex flex-col items-end gap-1 flex-shrink-0 text-right">
                  <span className="text-[10px] text-cinema-textMuted uppercase font-mono">
                    Fecha de Estreno
                  </span>
                  <span className="text-xs font-mono font-bold text-white">
                    {movie.releaseDate || movie.releaseYear}
                  </span>
                </div>
              </div>
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
                <div className="flex items-center gap-2">
                  <Globe className="w-4 h-4 text-cinema-gold" />
                  <h2 className="text-sm font-bold text-cinema-textSecondary uppercase tracking-wider">
                    Críticas de la Comunidad ({communityReviews.length})
                  </h2>
                </div>
                {!currentUser.isPremium && (
                  <span className="text-[10px] text-cinema-gold font-medium bg-cinema-gold/10 px-2 py-0.5 rounded-full border border-cinema-gold/30">
                    Solo lectura (Plan Base)
                  </span>
                )}
              </div>

              {!currentUser.isPremium && (
                <div className="p-3.5 rounded-2xl bg-gradient-to-r from-amber-950/40 via-cinema-card to-cinema-card border border-cinema-gold/30 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-md">
                  <div className="flex items-center gap-2.5">
                    <div className="p-2 rounded-xl bg-amber-900/40 border border-cinema-gold/30 text-cinema-gold flex-shrink-0">
                      <Sparkles className="w-4 h-4" />
                    </div>
                    <div className="flex flex-col">
                      <span className="text-xs font-bold text-white">¿Quieres que tu opinión la lea el mundo?</span>
                      <span className="text-[11px] text-cinema-textMuted">
                        En el Plan Base tus comentarios son privados para tus amigos. Con la suscripción mensual se publican aquí para toda la comunidad cinéfila mundial.
                      </span>
                    </div>
                  </div>
                  <button
                    onClick={() =>
                      onOpenSubscriptionModal?.(
                        'Activa tu suscripción mensual para que tus críticas se publiquen en la comunidad mundial e interactuar sin límites.'
                      )
                    }
                    className="px-3 py-1.5 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold transition-all shadow whitespace-nowrap"
                  >
                    Mejorar a Global
                  </button>
                </div>
              )}

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
                          <span className="text-xs font-semibold text-white flex items-center gap-1.5">
                            {r.userName}
                            {r.userIsPremium && (
                              <span className="text-[9px] px-1.5 py-0.2 rounded-full bg-cinema-gold/20 text-cinema-gold border border-cinema-gold/30 font-bold">
                                Pro
                              </span>
                            )}
                          </span>
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
        currentUser={currentUser}
        onOpenSubscriptionModal={onOpenSubscriptionModal}
      />
    </>
  );
};

