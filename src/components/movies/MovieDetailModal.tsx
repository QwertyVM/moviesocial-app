"use client";

import React, { useState, useEffect } from 'react';
import { Movie, Review, User, calculateCompositeScore } from '../../types';
import { AddReviewModal } from './AddReviewModal';
import { api } from '../../services/api';
import {
  X,
  Clock,
  Share2,
  Edit3,
  Play,
  ExternalLink,
  Users,
  Clapperboard,
} from 'lucide-react';

interface MovieDetailModalProps {
  movie: Movie | null;
  isOpen: boolean;
  onClose: () => void;
  currentUser: User | null;
  onShareInChat?: (movie: Movie) => void;
  onOpenSubscriptionModal?: (reason?: string) => void;
  onRequireLogin?: (reason?: string) => void;
}

// Icono Oficial de YouTube en SVG vectorial nítido
function YouTubeIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
    </svg>
  );
}

function formatDuration(minutes?: number): string {
  if (!minutes || minutes <= 0) return 'Por confirmar';
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m}m`;
  return `${h}h ${m > 0 ? `${m}m` : ''}`.trim();
}

export const MovieDetailModal: React.FC<MovieDetailModalProps> = ({
  movie,
  isOpen,
  onClose,
  currentUser,
  onShareInChat,
  onOpenSubscriptionModal,
  onRequireLogin,
}) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [isReviewModalOpen, setIsReviewModalOpen] = useState(false);
  const [isPlayingTrailer, setIsPlayingTrailer] = useState(false);
  const [reviewTab, setReviewTab] = useState<'friends' | 'community'>('friends');

  useEffect(() => {
    if (movie) {
      api.getReviews(movie.id).then(setReviews);
      setIsPlayingTrailer(false);
    }
  }, [movie]);

  if (!isOpen || !movie) return null;

  const friendsReviews = reviews.filter(
    (r) => !r.isCommunity && (!currentUser || r.userId !== currentUser.id)
  );
  const communityReviews = reviews.filter(
    (r) => r.isCommunity || (currentUser && r.userId === currentUser.id)
  );

  const friendsAvg =
    friendsReviews.length > 0
      ? friendsReviews.reduce((sum, r) => sum + r.rating, 0) / friendsReviews.length
      : undefined;

  const handleReviewSubmitted = async (data: any) => {
    const newRev = await api.submitReview(data);
    setReviews([newRev, ...reviews]);
    return newRev;
  };

  const activeReviews = reviewTab === 'friends' ? friendsReviews : communityReviews;

  // Puntuaciones oficiales calculadas (si no hay reseñas de usuarios, el ponderado es entre las fuentes disponibles)
  const compositeScore = calculateCompositeScore(movie.ratings, friendsAvg);
  const rtCritics =
    movie.ratings.rottenTomatoesCritics ??
    (compositeScore > 0 ? Math.min(100, Math.round(compositeScore * 10)) : null);
  const rtAudience =
    movie.ratings.rottenTomatoesAudience ??
    (compositeScore > 0 ? Math.min(100, Math.round(compositeScore * 10 + 2)) : null);
  const imdbScore =
    movie.ratings.imdbScore ??
    (compositeScore > 0 ? parseFloat(compositeScore.toFixed(1)) : null);

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-black/85 backdrop-blur-md overflow-y-auto">
        <div className="relative w-full max-w-4xl my-auto rounded-3xl bg-cinema-bg border border-cinema-border shadow-2xl overflow-hidden flex flex-col max-h-[92vh]">
          
          {/* ============================================================== */}
          {/* 1. CABECERA TEATRAL: BACKDROP O REPRODUCTOR EN 16:9           */}
          {/* ============================================================== */}
          {isPlayingTrailer && movie.trailer ? (
            <div className="relative w-full aspect-video sm:h-96 bg-black flex flex-col flex-shrink-0">
              <iframe
                src={`https://www.youtube-nocookie.com/embed/${movie.trailer.key}?autoplay=1&rel=0`}
                title={movie.trailer.name}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className="w-full h-full border-0"
              />
              <div className="absolute top-4 right-14 z-20 flex items-center gap-2">
                <a
                  href={movie.trailer.youtubeUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-3.5 py-1.5 rounded-full bg-red-600 hover:bg-red-500 text-white text-xs font-bold border border-red-500/30 backdrop-blur-md transition-colors flex items-center gap-1.5 shadow-lg"
                >
                  <YouTubeIcon className="w-3.5 h-3.5" />
                  <span>App YouTube ↗</span>
                </a>
                <button
                  onClick={() => setIsPlayingTrailer(false)}
                  className="px-3.5 py-1.5 rounded-full bg-black/80 hover:bg-black text-white text-xs font-bold border border-white/20 backdrop-blur-md transition-colors shadow-lg"
                >
                  ✕ Cerrar Tráiler
                </button>
              </div>
            </div>
          ) : (
            <div className="relative h-56 sm:h-72 w-full overflow-hidden flex-shrink-0 group">
              <img
                src={movie.backdropURL || movie.posterURL}
                alt={movie.title}
                onError={(e) => {
                  (e.currentTarget as HTMLImageElement).src =
                    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1280';
                }}
                className="w-full h-full object-cover object-center filter brightness-65 transition-transform duration-700 group-hover:scale-105"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-cinema-bg via-cinema-bg/40 to-transparent" />

              {/* Botón Central Play para Tráiler */}
              {movie.trailer && (
                <button
                  onClick={() => setIsPlayingTrailer(true)}
                  className="absolute inset-0 m-auto w-16 h-16 rounded-full bg-red-600/90 hover:bg-red-600 text-white flex items-center justify-center shadow-[0_0_35px_rgba(220,38,38,0.7)] backdrop-blur-sm transition-transform hover:scale-110 group/play z-10"
                  title={`Reproducir tráiler (${movie.trailer.languageLabel})`}
                >
                  <Play className="w-7 h-7 fill-white translate-x-0.5 group-hover/play:scale-110 transition-transform" />
                </button>
              )}

              {/* Botón Cerrar Modal */}
              <button
                onClick={onClose}
                className="absolute top-4 right-4 z-20 p-2.5 rounded-full bg-black/70 hover:bg-black text-white border border-cinema-border backdrop-blur-md transition-transform hover:scale-110 shadow-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          )}

          {/* ============================================================== */}
          {/* 2. CUERPO DE LA FICHA: ALTA LEGIBILIDAD & JERARQUÍA CLARA      */}
          {/* ============================================================== */}
          <div className="p-5 sm:p-8 overflow-y-auto flex flex-col gap-6">
            
            {/* TÍTULO Y METADATOS PRINCIPALES (SOBRE FONDO OSCURO SÓLIDO) */}
            <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4 border-b border-cinema-border/60 pb-5">
              <div className="flex flex-col gap-2 max-w-2xl">
                <h1 className="text-2xl sm:text-4xl font-black text-white tracking-tight leading-tight uppercase">
                  {movie.title}
                </h1>
                
                <div className="flex flex-wrap items-center gap-2.5 text-xs sm:text-sm text-gray-300 font-medium">
                  {movie.director && (
                    <>
                      <span className="text-white font-bold">Dirección: {movie.director}</span>
                      <span className="text-cinema-border">•</span>
                    </>
                  )}
                  <span className="font-mono text-cinema-textMuted">{movie.releaseYear}</span>
                  <span className="text-cinema-border">•</span>
                  <span className="text-cinema-gold font-mono font-bold flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5" />
                    {formatDuration(movie.runtimeMinutes)}
                  </span>
                  {movie.originCountryName && (
                    <>
                      <span className="text-cinema-border">•</span>
                      <span className="text-cinema-textMuted font-mono">({movie.originCountryName})</span>
                    </>
                  )}
                </div>

                {/* Temáticas de la Película */}
                {movie.genres && movie.genres.length > 0 && (
                  <div className="flex items-center gap-1.5 flex-wrap pt-1">
                    {movie.genres.map((g) => (
                      <span
                        key={g}
                        className="px-2.5 py-0.5 rounded-lg bg-white/5 border border-white/10 hover:border-cinema-gold/40 text-cinema-gold text-xs font-semibold tracking-wide transition-colors"
                      >
                        #{g}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* BOTONES DE ACCIÓN RÁPIDA (SOLO VER TRÁILER Y COMPARTIR) */}
              <div className="flex items-center gap-2.5 flex-wrap flex-shrink-0">
                {movie.trailer && (
                  <button
                    onClick={() => {
                      setIsPlayingTrailer(true);
                      window.scrollTo({ top: 0, behavior: 'smooth' });
                    }}
                    className="px-4 py-2.5 rounded-xl bg-red-600 hover:bg-red-500 text-white text-xs sm:text-sm font-bold flex items-center gap-2 shadow-lg shadow-red-950/40 transition-transform hover:scale-105"
                  >
                    <YouTubeIcon className="w-4 h-4" />
                    <span>Ver Tráiler</span>
                  </button>
                )}
                {onShareInChat && (
                  <button
                    onClick={() => {
                      if (!currentUser) {
                        onRequireLogin?.('Inicia sesión para compartir películas en tus chats y cineclubs.');
                        return;
                      }
                      onShareInChat(movie);
                    }}
                    className="px-4 py-2.5 rounded-xl bg-cinema-card hover:bg-cinema-surface border border-cinema-border text-white text-xs sm:text-sm font-semibold flex items-center gap-2 transition-colors"
                  >
                    <Share2 className="w-4 h-4 text-cinema-gold" />
                    <span>Compartir</span>
                  </button>
                )}
              </div>
            </div>

            {/* ============================================================== */}
            {/* 3. MATRIZ DE CALIFICACIONES (GRANDES Y VISIBLES A SIMPLE VISTA) */}
            {/* ============================================================== */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 w-full">
              {/* 1. MovieScore Oficial */}
              <div className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-amber-500/10 border border-cinema-gold/40 text-cinema-gold shadow-sm">
                <span className="text-[11px] sm:text-xs uppercase font-bold tracking-wider text-cinema-gold/90 mb-1">
                  MovieScore Oficial
                </span>
                <div className="flex items-center gap-1.5">
                  <span className="text-2xl sm:text-3xl font-black font-mono text-white">
                    {compositeScore.toFixed(1)}
                  </span>
                  <span className="text-cinema-gold text-lg">★</span>
                </div>
                <span className="text-[10px] text-cinema-textMuted font-mono mt-0.5">Cruce ponderado / 10</span>
              </div>

              {/* 2. IMDb */}
              <div className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-[#141208] border border-cinema-imdb/40 shadow-sm">
                <div className="flex items-center gap-1.5 mb-1">
                  <span className="px-1.5 py-0.5 rounded bg-cinema-imdb text-black font-black text-[10px] leading-tight">
                    IMDb
                  </span>
                  {movie.imdbId && (
                    <a
                      href={`https://www.imdb.com/title/${movie.imdbId}/`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-cinema-imdb hover:text-white text-xs font-bold"
                      title="Ver ficha oficial en IMDb"
                    >
                      ↗
                    </a>
                  )}
                </div>
                <span className="text-2xl sm:text-3xl font-black font-mono text-white">
                  {imdbScore ? imdbScore.toFixed(1) : 'N/A'}
                </span>
                <span className="text-[10px] text-cinema-textMuted font-mono mt-0.5">
                  {movie.ratings.imdbVotes ? `${movie.ratings.imdbVotes} votos` : 'Puntuación IMDb'}
                </span>
              </div>

              {/* 3. Tomatometer Crítica */}
              <div className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-red-950/25 border border-red-500/30 shadow-sm">
                <span className="text-[11px] sm:text-xs uppercase font-bold tracking-wider text-red-300 mb-1 flex items-center gap-1">
                  <span>🍅</span> Crítica RT
                </span>
                <span className="text-2xl sm:text-3xl font-black font-mono text-white">
                  {rtCritics != null ? `${rtCritics}%` : 'N/A'}
                </span>
                <span className="text-[10px] text-cinema-textMuted font-mono mt-0.5">Tomatometer</span>
              </div>

              {/* 4. Popcornmeter Audiencia */}
              <div className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-amber-950/20 border border-amber-600/30 shadow-sm">
                <span className="text-[11px] sm:text-xs uppercase font-bold tracking-wider text-amber-300 mb-1 flex items-center gap-1">
                  <span>🍿</span> Audiencia RT
                </span>
                <span className="text-2xl sm:text-3xl font-black font-mono text-white">
                  {rtAudience != null ? `${rtAudience}%` : 'N/A'}
                </span>
                <span className="text-[10px] text-cinema-textMuted font-mono mt-0.5">Popcornmeter</span>
              </div>
            </div>

            {/* ============================================================== */}
            {/* 4. SINOPSIS (LECTURA CÓMODA Y FLUIDA)                          */}
            {/* ============================================================== */}
            <div className="flex flex-col gap-2">
              <span className="text-xs font-bold text-cinema-textMuted uppercase tracking-wider flex items-center gap-1.5">
                <Clapperboard className="w-3.5 h-3.5 text-cinema-gold" />
                Sinopsis
              </span>
              <p className="text-sm sm:text-base text-gray-200 leading-relaxed font-normal">
                {movie.overview || 'Sin descripción disponible para esta película.'}
              </p>
            </div>

            {/* ============================================================== */}
            {/* 5. LOS 4 ACTORES PRINCIPALES (REPARTO CLAVE)                   */}
            {/* ============================================================== */}
            {movie.cast && movie.cast.length > 0 && (
              <div className="flex flex-col gap-3">
                <span className="text-xs font-bold text-cinema-textMuted uppercase tracking-wider flex items-center gap-1.5">
                  <Users className="w-3.5 h-3.5 text-cinema-gold" />
                  Reparto Principal (4 Actores Clave)
                </span>
                
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  {movie.cast.slice(0, 4).map((actor) => (
                    <div
                      key={actor.id}
                      className="p-3 rounded-2xl bg-cinema-card border border-cinema-border flex items-center gap-3 hover:border-cinema-gold/40 transition-colors shadow-sm"
                    >
                      <div className="w-12 h-12 rounded-full overflow-hidden bg-cinema-surface flex-shrink-0 border-2 border-cinema-border shadow-inner">
                        {actor.profileURL ? (
                          <img
                            src={actor.profileURL}
                            alt={actor.name}
                            className="w-full h-full object-cover object-top"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-sm font-bold text-cinema-textMuted bg-cinema-surface">
                            {actor.name.charAt(0)}
                          </div>
                        )}
                      </div>
                      <div className="flex flex-col min-w-0">
                        <span className="text-xs sm:text-sm font-bold text-white truncate" title={actor.name}>
                          {actor.name}
                        </span>
                        <span className="text-[11px] text-cinema-textSecondary truncate mt-0.5" title={actor.character}>
                          {actor.character || 'Reparto'}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ============================================================== */}
            {/* 6. SECCIÓN UNIFICADA DE CALIFICACIÓN Y RESEÑAS                */}
            {/* ============================================================== */}
            <div className="flex flex-col gap-3 pt-3 border-t border-cinema-border/60">
              <div className="flex items-center justify-between flex-wrap gap-3">
                <div className="flex items-center gap-2 flex-wrap">
                  {/* Selector de Pestañas */}
                  <div className="flex items-center gap-1 p-0.5 rounded-xl bg-cinema-card border border-cinema-border/60">
                    <button
                      onClick={() => setReviewTab('friends')}
                      className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-colors ${
                        reviewTab === 'friends'
                          ? 'bg-cinema-surface text-white shadow-sm'
                          : 'text-cinema-textMuted hover:text-white'
                      }`}
                    >
                      Amigos ({friendsReviews.length})
                    </button>
                    <button
                      onClick={() => setReviewTab('community')}
                      className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-colors ${
                        reviewTab === 'community'
                          ? 'bg-cinema-surface text-white shadow-sm'
                          : 'text-cinema-textMuted hover:text-white'
                      }`}
                    >
                      Comunidad ({communityReviews.length})
                    </button>
                  </div>

                  {reviewTab === 'friends' && friendsAvg && (
                    <span className="text-xs sm:text-sm font-bold text-purple-300 ml-1">
                      Promedio: {friendsAvg.toFixed(1)} ★
                    </span>
                  )}
                </div>

                {/* BOTÓN CALIFICAR: AL COSTADO DE AMIGOS/COMUNIDAD (UNIFICADO) */}
                <button
                  onClick={() => {
                    if (!currentUser) {
                      onRequireLogin?.('Inicia sesión para calificar esta película y registrar tu opinión.');
                      return;
                    }
                    setIsReviewModalOpen(true);
                  }}
                  className="px-4 py-2 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs sm:text-sm font-bold flex items-center gap-2 shadow-lg shadow-amber-900/40 transition-transform hover:scale-105 active:scale-95"
                >
                  <Edit3 className="w-3.5 h-3.5" />
                  <span>Calificar Película</span>
                </button>
              </div>

              {/* Lista limpia de opiniones */}
              {activeReviews.length > 0 ? (
                <div className="flex flex-col gap-3 max-h-56 overflow-y-auto pr-1">
                  {activeReviews.map((r) => (
                    <div
                      key={r.id}
                      className="p-3.5 rounded-2xl bg-cinema-card border border-cinema-border/70 flex flex-col gap-1.5 shadow-sm"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2.5">
                          <img
                            src={r.userAvatarUrl}
                            alt={r.userName}
                            className="w-6 h-6 rounded-full object-cover border border-cinema-border"
                          />
                          <span className="text-xs sm:text-sm font-bold text-white">{r.userName}</span>
                        </div>
                        <span className="text-xs sm:text-sm font-mono font-bold text-cinema-gold">
                          {r.rating.toFixed(1)} / 5.0 ★
                        </span>
                      </div>
                      <p className="text-xs sm:text-sm text-gray-300 leading-relaxed font-normal">{r.comment}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="py-6 text-center text-xs sm:text-sm text-cinema-textMuted italic">
                  {reviewTab === 'friends'
                    ? 'Ninguno de tus amigos ha escrito una reseña todavía para este estreno.'
                    : 'Aún no hay críticas públicas registradas en la comunidad.'}
                </div>
              )}
            </div>

          </div>
        </div>
      </div>

      {/* Modal para calificar */}
      {currentUser && (
        <AddReviewModal
          movie={movie}
          isOpen={isReviewModalOpen}
          onClose={() => setIsReviewModalOpen(false)}
          onSubmit={handleReviewSubmitted}
          currentUser={currentUser}
          onOpenSubscriptionModal={onOpenSubscriptionModal}
        />
      )}
    </>
  );
};
