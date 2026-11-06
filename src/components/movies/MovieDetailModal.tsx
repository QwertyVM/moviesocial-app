"use client";

import React, { useState, useEffect } from 'react';
import { Movie, Review, User, calculateCompositeScore, UserMovieStatus } from '../../types';
import { AddReviewModal } from './AddReviewModal';
import { api } from '../../services/api';
import {
  X,
  Clock,
  Share2,
  Edit3,
  Play,
  Users,
  Clapperboard,
  Star,
  Bookmark,
  BookmarkCheck,
  Check,
  Heart,
  Eye,
  Sparkles,
  Building2,
  DollarSign,
  Send,
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

  // Estados personales (Mejora 2: Watchlist, Ya la vi, Favorita)
  const [inWatchlist, setInWatchlist] = useState(false);
  const [isWatched, setIsWatched] = useState(false);
  const [isFavorite, setIsFavorite] = useState(false);
  const [savingStatus, setSavingStatus] = useState(false);

  // Círculo social de amigos interesados (Mejora 3)
  const [friendsInterested, setFriendsInterested] = useState<Array<{ id: string; displayName: string; avatarUrl?: string }>>([]);

  // Calificación interactiva 1-clic (Mejora 1)
  const [userRating, setUserRating] = useState<number | null>(null);
  const [hoverStar, setHoverStar] = useState<number | null>(null);
  const [isSubmittingRating, setIsSubmittingRating] = useState(false);
  const [quickComment, setQuickComment] = useState('');
  const [showCommentBox, setShowCommentBox] = useState(false);
  const [ratingSuccessMsg, setRatingSuccessMsg] = useState<string | null>(null);

  // Cargar reseñas, estado personal e interés de amigos
  useEffect(() => {
    if (movie) {
      api.getReviews(movie.id).then((revList) => {
        setReviews(revList);
        if (currentUser) {
          const myRev = revList.find((r) => r.userId === currentUser.id);
          if (myRev) {
            setUserRating(myRev.rating);
            setQuickComment(myRev.comment || '');
          } else {
            setUserRating(null);
            setQuickComment('');
          }
        }
      });

      api.getMovieStatus(movie.id, currentUser?.id).then((status) => {
        setInWatchlist(status.inWatchlist);
        setIsWatched(status.isWatched);
        setIsFavorite(status.isFavorite);
        setFriendsInterested(status.friendsInterested || []);
      });

      setIsPlayingTrailer(false);
      setShowCommentBox(false);
      setRatingSuccessMsg(null);
    }
  }, [movie, currentUser]);

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

  const communityAvg =
    reviews.length > 0
      ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
      : undefined;

  // Toggle de estados personales (Mejora 2)
  const handleToggleStatus = async (action: 'toggle_watchlist' | 'toggle_watched' | 'toggle_favorite') => {
    if (!currentUser) {
      onRequireLogin?.('Inicia sesión para gestionar tu historial y lista de películas.');
      return;
    }
    if (savingStatus) return;

    setSavingStatus(true);
    // Actualización optimista inmediata
    if (action === 'toggle_watchlist') setInWatchlist(!inWatchlist);
    if (action === 'toggle_watched') setIsWatched(!isWatched);
    if (action === 'toggle_favorite') setIsFavorite(!isFavorite);

    try {
      const updated = await api.toggleMovieStatus(movie, action, currentUser.id);
      setInWatchlist(updated.inWatchlist);
      setIsWatched(updated.isWatched);
      setIsFavorite(updated.isFavorite);
    } catch (err: any) {
      console.warn('Error al actualizar estado:', err);
    } finally {
      setSavingStatus(false);
    }
  };

  // Calificación rápida de 1-clic (Mejora 1)
  const handleOneClickRating = async (stars: number) => {
    if (!currentUser) {
      onRequireLogin?.('Inicia sesión para calificar esta película con 1 clic.');
      return;
    }

    setUserRating(stars);
    setIsSubmittingRating(true);
    setRatingSuccessMsg(`¡Calificaste con ${stars.toFixed(1)} ★!`);

    try {
      const newRev = await api.submitReview({
        movieId: movie.id,
        movieTitle: movie.title,
        moviePosterUrl: movie.posterURL,
        movieReleaseYear: movie.releaseYear,
        rating: stars,
        comment: quickComment || '',
        isCommunity: true,
      });

      // Actualizar lista de reseñas en tiempo real
      setReviews((prev) => {
        const filtered = prev.filter((r) => r.userId !== currentUser.id);
        return [newRev, ...filtered];
      });

      setShowCommentBox(true);
      setTimeout(() => setRatingSuccessMsg(null), 3500);
    } catch (err: any) {
      alert(err.message || 'Error al guardar tu calificación');
    } finally {
      setIsSubmittingRating(false);
    }
  };

  // Guardar comentario opcional tras calificar
  const handleSaveQuickComment = async () => {
    if (!currentUser || !userRating) return;
    setIsSubmittingRating(true);
    try {
      const newRev = await api.submitReview({
        movieId: movie.id,
        movieTitle: movie.title,
        moviePosterUrl: movie.posterURL,
        movieReleaseYear: movie.releaseYear,
        rating: userRating,
        comment: quickComment,
        isCommunity: true,
      });

      setReviews((prev) => {
        const filtered = prev.filter((r) => r.userId !== currentUser.id);
        return [newRev, ...filtered];
      });

      setRatingSuccessMsg('¡Crítica guardada en la comunidad!');
      setTimeout(() => setRatingSuccessMsg(null), 3000);
    } catch (err: any) {
      alert(err.message || 'Error al guardar tu nota');
    } finally {
      setIsSubmittingRating(false);
    }
  };

  const handleFullReviewSubmitted = async (data: any) => {
    const newRev = await api.submitReview(data);
    setReviews([newRev, ...reviews.filter((r) => r.id !== newRev.id)]);
    setUserRating(newRev.rating);
    return newRev;
  };

  const activeReviews = reviewTab === 'friends' ? friendsReviews : communityReviews;

  // Puntuaciones oficiales calculadas
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
            <div className="relative h-52 sm:h-72 w-full overflow-hidden flex-shrink-0 group">
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
                  title={`Reproducir tráiler oficial (${movie.trailer.languageLabel})`}
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
            
            {/* TÍTULO Y METADATOS PRINCIPALES */}
            <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4 border-b border-cinema-border/60 pb-5">
              <div className="flex flex-col gap-2 max-w-2xl">
                <h1 className="text-2xl sm:text-4xl font-black text-white tracking-tight leading-tight uppercase">
                  {movie.title}
                </h1>
                
                {/* Metadatos Técnicos Enriquecidos (Director, Duración, Distribuidora y Taquilla) */}
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
                  
                  {/* Distribuidora / Productora Oficial (Mejora 5) */}
                  {movie.productionCompany && (
                    <>
                      <span className="text-cinema-border">•</span>
                      <span className="text-gray-300 flex items-center gap-1 font-medium">
                        <Building2 className="w-3.5 h-3.5 text-cinema-textMuted" />
                        <span>{movie.productionCompany}</span>
                      </span>
                    </>
                  )}

                  {/* Taquilla Mundial Oficial si está disponible (Mejora 5) */}
                  {movie.boxOfficeFormatted && (
                    <>
                      <span className="text-cinema-border">•</span>
                      <span className="text-emerald-400 font-mono font-semibold flex items-center gap-1">
                        <DollarSign className="w-3.5 h-3.5" />
                        <span>Taquilla: {movie.boxOfficeFormatted}</span>
                      </span>
                    </>
                  )}

                  {movie.originCountryName && (
                    <>
                      <span className="text-cinema-border">•</span>
                      <span className="text-cinema-textMuted font-mono">({movie.originCountryName})</span>
                    </>
                  )}
                </div>

                {/* Categorías Temáticas (Sin hashtag) */}
                {movie.genres && movie.genres.length > 0 && (
                  <div className="flex items-center gap-1.5 flex-wrap pt-1">
                    {movie.genres.map((g) => (
                      <span
                        key={g}
                        className="px-3 py-1 rounded-full bg-white/5 border border-white/10 hover:border-cinema-gold/40 text-cinema-gold text-xs font-semibold tracking-wide transition-colors"
                      >
                        {g}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* BOTONES DE ACCIÓN: TRÁILER Y COMPARTIR */}
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
            {/* MEJORA 2: 3 PASTILLAS DE ESTADO PERSONAL CINÉFILO             */}
            {/* [ + Quiero Verla ] [ ✓ Ya la vi ] [ ♥ Favorita ]               */}
            {/* ============================================================== */}
            <div className="flex items-center gap-2.5 flex-wrap">
              {/* Pastilla 1: Quiero Verla (Watchlist) */}
              <button
                onClick={() => handleToggleStatus('toggle_watchlist')}
                disabled={savingStatus}
                className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-2 transition-all shadow-sm ${
                  inWatchlist
                    ? 'bg-amber-500/20 text-cinema-gold border-2 border-cinema-gold/70'
                    : 'bg-cinema-card hover:bg-cinema-surface text-gray-300 border border-cinema-border'
                }`}
                title="Guardar en tu lista de películas por ver"
              >
                {inWatchlist ? (
                  <>
                    <BookmarkCheck className="w-4 h-4 text-cinema-gold fill-cinema-gold" />
                    <span>En tu Watchlist</span>
                  </>
                ) : (
                  <>
                    <Bookmark className="w-4 h-4 text-cinema-gold" />
                    <span>Quiero Verla</span>
                  </>
                )}
              </button>

              {/* Pastilla 2: Ya la vi (Historial de Visionado) */}
              <button
                onClick={() => handleToggleStatus('toggle_watched')}
                disabled={savingStatus}
                className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-2 transition-all shadow-sm ${
                  isWatched
                    ? 'bg-emerald-500/20 text-emerald-400 border-2 border-emerald-500/70'
                    : 'bg-cinema-card hover:bg-cinema-surface text-gray-300 border border-cinema-border'
                }`}
                title="Marcar como ya vista en tu historial cinéfilo"
              >
                <Eye className={`w-4 h-4 ${isWatched ? 'text-emerald-400 fill-emerald-400/20' : 'text-gray-400'}`} />
                <span>{isWatched ? 'Ya la vi ✓' : 'Marcar: Ya la vi'}</span>
              </button>

              {/* Pastilla 3: Favorita (Top de Películas) */}
              <button
                onClick={() => handleToggleStatus('toggle_favorite')}
                disabled={savingStatus}
                className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-2 transition-all shadow-sm ${
                  isFavorite
                    ? 'bg-rose-500/20 text-rose-400 border-2 border-rose-500/70'
                    : 'bg-cinema-card hover:bg-cinema-surface text-gray-300 border border-cinema-border'
                }`}
                title="Marcar como una de tus películas favoritas de culto"
              >
                <Heart className={`w-4 h-4 ${isFavorite ? 'text-rose-400 fill-rose-400' : 'text-gray-400'}`} />
                <span>{isFavorite ? 'En Favoritas ♥' : 'Favorita'}</span>
              </button>
            </div>

            {/* ============================================================== */}
            {/* MEJORA 3: INDICADOR DE CÍRCULO SOCIAL DE AMIGOS INTERESADOS    */}
            {/* ============================================================== */}
            {friendsInterested.length > 0 && (
              <div className="flex items-center gap-3 p-3 sm:p-3.5 rounded-2xl bg-cinema-card/70 border border-cinema-border text-xs">
                <div className="flex -space-x-2 overflow-hidden flex-shrink-0">
                  {friendsInterested.slice(0, 3).map((f) => (
                    <img
                      key={f.id}
                      src={f.avatarUrl}
                      alt={f.displayName}
                      title={f.displayName}
                      className="inline-block h-7 w-7 rounded-full ring-2 ring-cinema-bg object-cover"
                    />
                  ))}
                </div>
                <div className="flex flex-col sm:flex-row sm:items-center gap-0.5 sm:gap-1.5 leading-tight">
                  <span className="text-gray-300 font-medium">
                    A <strong className="text-white font-bold">{friendsInterested.length} cinéfilos de tu círculo</strong> les interesa ver este estreno:
                  </span>
                  <span className="text-cinema-gold font-bold">
                    {friendsInterested.map((f) => f.displayName).join(', ')}
                  </span>
                </div>
              </div>
            )}

            {/* ============================================================== */}
            {/* 3. MATRIZ DE CALIFICACIONES (INCLUYENDO COMUNIDAD MOVIESOCIAL) */}
            {/* ============================================================== */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 w-full">
              {/* 1. Rating Oficial (Ponderado de Crítica Internacional) */}
              <div className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-amber-500/10 border border-cinema-gold/40 text-cinema-gold shadow-sm">
                <span className="text-[11px] sm:text-xs uppercase font-bold tracking-wider text-cinema-gold/90 mb-1 flex items-center gap-1">
                  <Sparkles className="w-3.5 h-3.5 fill-cinema-gold" />
                  <span>Rating Oficial</span>
                </span>
                <div className="flex items-center gap-1.5">
                  <span className="text-2xl sm:text-3xl font-black font-mono text-white">
                    {compositeScore.toFixed(1)}
                  </span>
                  <span className="text-cinema-gold text-lg">★</span>
                </div>
                <span className="text-[10px] text-cinema-textMuted font-mono mt-0.5">Consenso Crítica / 10</span>
              </div>

              {/* 2. ITEM DEDICADO: Comunidad MovieSocial (Calificaciones de Nuestros Usuarios) */}
              <div className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-indigo-950/25 border border-indigo-500/40 shadow-sm text-indigo-300">
                <span className="text-[11px] sm:text-xs uppercase font-bold tracking-wider text-indigo-300 mb-1 flex items-center gap-1">
                  <Users className="w-3.5 h-3.5 text-indigo-400" />
                  <span>Comunidad MovieSocial</span>
                </span>
                <div className="flex items-center gap-1.5">
                  <span className="text-2xl sm:text-3xl font-black font-mono text-white">
                    {communityAvg ? communityAvg.toFixed(1) : '-'}
                  </span>
                  <span className="text-indigo-400 text-lg">★</span>
                </div>
                <span className="text-[10px] text-cinema-textMuted font-mono mt-0.5">
                  {reviews.length > 0 ? `${reviews.length} votos en plataforma` : 'Aún sin calificaciones'}
                </span>
              </div>

              {/* 3. IMDb */}
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

              {/* 4. Rotten Tomatoes (Crítica y Audiencia) */}
              <div className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-red-950/20 border border-red-500/30 shadow-sm">
                <span className="text-[11px] sm:text-xs uppercase font-bold tracking-wider text-red-300 mb-1 flex items-center gap-1">
                  <span>🍅</span> Tomatometer
                </span>
                <div className="flex items-center gap-2">
                  <span className="text-2xl sm:text-3xl font-black font-mono text-white">
                    {rtCritics != null ? `${rtCritics}%` : 'N/A'}
                  </span>
                  {rtAudience != null && (
                    <span className="text-xs text-cinema-textMuted font-mono">
                      (🍿 {rtAudience}%)
                    </span>
                  )}
                </div>
                <span className="text-[10px] text-cinema-textMuted font-mono mt-0.5">Crítica Oficial RT</span>
              </div>
            </div>

            {/* ============================================================== */}
            {/* MEJORA 1: CALIFICACIÓN RÁPIDA 1-CLIC DE 5 ESTRELLAS DIRECTA   */}
            {/* ============================================================== */}
            <div className="flex flex-col gap-2.5 p-4 rounded-2xl bg-gradient-to-r from-amber-500/10 via-cinema-card to-cinema-surface border border-cinema-gold/40 shadow-inner">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5">
                    <Star className="w-4 h-4 text-cinema-gold fill-cinema-gold" />
                    <span>Tu Calificación Cinéfila (1 Clic)</span>
                  </span>
                  <span className="text-[11px] text-cinema-textMuted mt-0.5">
                    {userRating
                      ? `Has calificado esta película con ${userRating.toFixed(1)} ★`
                      : 'Haz clic en una estrella para registrar tu valoración de inmediato'}
                  </span>
                </div>

                {/* 5 Estrellas Interactivas */}
                <div className="flex items-center gap-1.5 bg-black/40 px-3 py-1.5 rounded-2xl border border-cinema-border/70">
                  {[1, 2, 3, 4, 5].map((starVal) => {
                    const isLit = hoverStar !== null ? starVal <= hoverStar : (userRating !== null && starVal <= userRating);
                    return (
                      <button
                        key={starVal}
                        onClick={() => handleOneClickRating(starVal)}
                        onMouseEnter={() => setHoverStar(starVal)}
                        onMouseLeave={() => setHoverStar(null)}
                        disabled={isSubmittingRating}
                        className="p-1 transition-transform hover:scale-125 focus:outline-none cursor-pointer"
                        title={`${starVal} de 5 estrellas`}
                      >
                        <Star
                          className={`w-6 h-6 transition-colors ${
                            isLit
                              ? 'text-cinema-gold fill-cinema-gold drop-shadow-[0_0_8px_rgba(229,169,60,0.6)]'
                              : 'text-cinema-textMuted/40 hover:text-cinema-gold/60'
                          }`}
                        />
                      </button>
                    );
                  })}
                  {userRating && (
                    <span className="text-xs font-mono font-bold text-cinema-gold ml-1">
                      {userRating.toFixed(1)} ★
                    </span>
                  )}
                </div>
              </div>

              {/* Mensaje de Confirmación Rápida */}
              {ratingSuccessMsg && (
                <div className="flex items-center gap-1.5 text-xs text-emerald-400 font-semibold pt-1">
                  <Check className="w-3.5 h-3.5" />
                  <span>{ratingSuccessMsg}</span>
                </div>
              )}

              {/* Caja opcional de pensamiento/crítica rápida tras calificar */}
              {(showCommentBox || userRating) && (
                <div className="flex flex-col sm:flex-row items-center gap-2 pt-2 border-t border-cinema-border/40">
                  <input
                    type="text"
                    value={quickComment}
                    onChange={(e) => setQuickComment(e.target.value)}
                    placeholder="Escribe una breve opinión cinéfila (opcional)..."
                    className="w-full px-3 py-2 rounded-xl bg-cinema-bg border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none"
                  />
                  <button
                    onClick={handleSaveQuickComment}
                    disabled={isSubmittingRating}
                    className="px-4 py-2 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold whitespace-nowrap flex items-center gap-1.5 transition-transform hover:scale-105 active:scale-95"
                  >
                    <Send className="w-3 h-3" />
                    <span>Publicar Opinión</span>
                  </button>
                </div>
              )}
            </div>

            {/* ============================================================== */}
            {/* 4. SINOPSIS                                                    */}
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
            {/* 6. SECCIÓN DE DEBATE Y CRÍTICAS (AMIGOS & COMUNIDAD)           */}
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
                      Promedio amigos: {friendsAvg.toFixed(1)} ★
                    </span>
                  )}
                </div>

                {/* BOTÓN RESEÑA DETALLADA: Abre modal completo si se desea crítica extensa */}
                <button
                  onClick={() => {
                    if (!currentUser) {
                      onRequireLogin?.('Inicia sesión para escribir una crítica completa.');
                      return;
                    }
                    setIsReviewModalOpen(true);
                  }}
                  className="px-4 py-2 rounded-xl bg-cinema-card hover:bg-cinema-surface border border-cinema-border hover:border-cinema-gold/40 text-cinema-gold text-xs sm:text-sm font-bold flex items-center gap-2 transition-colors"
                >
                  <Edit3 className="w-3.5 h-3.5" />
                  <span>Escribir Crítica Extensa</span>
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

      {/* Modal para calificar de forma extendida */}
      {currentUser && (
        <AddReviewModal
          movie={movie}
          isOpen={isReviewModalOpen}
          onClose={() => setIsReviewModalOpen(false)}
          onSubmit={handleFullReviewSubmitted}
          currentUser={currentUser}
          onOpenSubscriptionModal={onOpenSubscriptionModal}
        />
      )}
    </>
  );
};
