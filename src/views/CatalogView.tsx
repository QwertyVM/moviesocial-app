"use client";

import React, { useState, useEffect, useRef } from 'react';
import { Movie, User, UserLocation, Friend, calculateCompositeScore } from '../types';
import { api } from '../services/api';
import { CinephileSpotlightData } from '@/actions/movies';
import {
  Film,
  Sparkles,
  Clapperboard,
  Award,
  ChevronLeft,
  ChevronRight,
  Clock,
  Share2,
  Bookmark,
  BookmarkCheck,
  Send,
  Check,
  Copy,
} from 'lucide-react';

interface CatalogViewProps {
  currentUser?: User | null;
  location?: UserLocation;
  onSelectMovie: (movie: Movie) => void;
  initialCategory?: 'nowPlaying' | 'classics' | 'catalog';
  lens?: 'friends' | 'global';
  onOpenAuthModal?: (mode: 'login' | 'register', reason?: string) => void;
  onOpenChatWithFriend?: (friend: Friend) => void;
}

function formatDuration(minutes?: number): string {
  if (!minutes || minutes <= 0) return 'Por confirmar';
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m}m`;
  return `${h}h ${m > 0 ? `${m}m` : ''}`.trim();
}

// Icono Oficial de WhatsApp en SVG vectorial nítido para web y móvil
function WhatsAppIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="currentColor"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L0 24l6.335-1.662c1.746.953 3.71 1.456 5.711 1.457h.005c6.554 0 11.89-5.335 11.893-11.893a11.82 11.82 0 00-3.487-8.413Z" />
    </svg>
  );
}

// Icono Oficial de YouTube en SVG vectorial nítido
function YouTubeIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
    </svg>
  );
}

export const CatalogView: React.FC<CatalogViewProps> = ({
  currentUser,
  location,
  onSelectMovie,
  onOpenAuthModal,
  onOpenChatWithFriend,
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

  const [movies, setMovies] = useState<Movie[]>([]);
  const [spotlight, setSpotlight] = useState<CinephileSpotlightData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  // Índice del estreno principal enfocado en la Gran Cartelera
  const [activeIdx, setActiveIdx] = useState<number>(0);

  // Watchlist de usuario
  const [watchlistIds, setWatchlistIds] = useState<string[]>([]);
  const [savingWatchlist, setSavingWatchlist] = useState(false);

  // Modal para compartir (WhatsApp + Chat Interno + Enlace)
  const [isShareModalOpen, setIsShareModalOpen] = useState(false);
  const [friendsList, setFriendsList] = useState<Friend[]>([]);
  const [sendingChatShare, setSendingChatShare] = useState(false);
  const [copiedLink, setCopiedLink] = useState(false);

  // Refs para gestos e interacción infinita
  const touchStartX = useRef<number | null>(null);
  const reelTouchStartX = useRef<number | null>(null);
  const lastWheelTime = useRef<number>(0);
  const activeThumbRef = useRef<HTMLButtonElement | null>(null);
  const reelContainerRef = useRef<HTMLDivElement | null>(null);

  // Cargar spotlight de estrenos
  useEffect(() => {
    api.getSpotlight(activeLocation.countryCode).then(setSpotlight);
  }, [activeLocation.countryCode]);

  // Cargar Watchlist del usuario
  useEffect(() => {
    if (currentUser) {
      api.getWatchlist(currentUser.id).then(setWatchlistIds);
    } else {
      setWatchlistIds([]);
    }
  }, [currentUser]);

  // Cargar estrictamente películas de Estreno en Cartelera
  const loadPremiereMovies = async () => {
    setLoading(true);
    const data = await api.getMovies({
      category: 'nowPlaying',
      city: activeLocation.city,
      countryCode: activeLocation.countryCode,
      sortBy: 'ratingDesc',
    });
    setMovies(data);
    setLoading(false);
    setActiveIdx(0);
  };

  useEffect(() => {
    loadPremiereMovies();
  }, [activeLocation.countryCode, activeLocation.city]);

  const n = movies.length;
  const activeMovie = n > 0 ? movies[Math.min(activeIdx, n - 1)] : null;
  const isSpotlight = Boolean(activeMovie && spotlight && spotlight.movie.id === activeMovie.id);

  // Navegación en bucle infinito
  const goToNext = () => {
    if (n === 0) return;
    setActiveIdx((prev) => (prev + 1) % n);
  };

  const goToPrev = () => {
    if (n === 0) return;
    setActiveIdx((prev) => (prev - 1 + n) % n);
  };

  // Rotación con la rueda del ratón
  const handleWheelLoop = (e: React.WheelEvent) => {
    const now = Date.now();
    if (now - lastWheelTime.current < 260) return;
    if (Math.abs(e.deltaX) > 15 || Math.abs(e.deltaY) > 15) {
      lastWheelTime.current = now;
      if (e.deltaX > 0 || e.deltaY > 0) goToNext();
      else goToPrev();
    }
  };

  // Deslizamiento táctil móvil
  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (touchStartX.current === null) return;
    const diff = touchStartX.current - e.changedTouches[0].clientX;
    if (Math.abs(diff) > 35) {
      if (diff > 0) goToNext();
      else goToPrev();
    }
    touchStartX.current = null;
  };

  // Swipe táctil en el carrete inferior
  const handleReelTouchStart = (e: React.TouchEvent) => {
    reelTouchStartX.current = e.touches[0].clientX;
  };

  const handleReelTouchEnd = (e: React.TouchEvent) => {
    if (reelTouchStartX.current === null) return;
    const diff = reelTouchStartX.current - e.changedTouches[0].clientX;
    if (Math.abs(diff) > 30) {
      if (diff > 0) goToNext();
      else goToPrev();
    }
    reelTouchStartX.current = null;
  };

  // Atajos de teclado
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight') goToNext();
      if (e.key === 'ArrowLeft') goToPrev();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [n]);

  // Puntuaciones oficiales
  const compositeScore = activeMovie ? calculateCompositeScore(activeMovie.ratings) : 0;
  const rtCritics = activeMovie
    ? activeMovie.ratings.rottenTomatoesCritics ?? (compositeScore > 0 ? Math.min(100, Math.round(compositeScore * 10)) : null)
    : null;
  const rtAudience =
    activeMovie?.ratings.rottenTomatoesAudience ??
    (compositeScore > 0 ? Math.min(100, Math.round(compositeScore * 10 + 2)) : null);
  const imdbScore = activeMovie
    ? activeMovie.ratings.imdbScore ?? (compositeScore > 0 ? parseFloat(compositeScore.toFixed(1)) : null)
    : null;

  // Watchlist toggle
  const isInWatchlist = Boolean(activeMovie && watchlistIds.includes(activeMovie.id));

  const handleToggleWatchlist = async () => {
    if (!currentUser) {
      onOpenAuthModal?.(
        'login',
        'Inicia sesión para guardar películas en tu Watchlist personal.'
      );
      return;
    }
    if (!activeMovie || savingWatchlist) return;

    setSavingWatchlist(true);
    try {
      const res = await api.toggleWatchlist(activeMovie, currentUser.id);
      setWatchlistIds(res.movieIds);
    } catch (err: any) {
      alert(err.message || 'Error al actualizar tu Watchlist');
    } finally {
      setSavingWatchlist(false);
    }
  };

  // Abrir modal de compartir
  const handleOpenShareModal = async () => {
    if (currentUser) {
      api.getFriendsAndCommunity().then((data) => {
        setFriendsList(data.friends || []);
      });
    }
    setIsShareModalOpen(true);
  };

  // Compartir por WhatsApp
  const handleShareWhatsApp = () => {
    if (!activeMovie) return;
    const origin = typeof window !== 'undefined' ? window.location.origin : 'https://moviesocial.app';
    const text =
      `🎬 *${activeMovie.title}* (${activeMovie.releaseYear})\n` +
      `⭐ MovieScore Oficial: ${compositeScore.toFixed(1)} / 10\n` +
      (rtCritics != null ? `🍅 Tomatometer: ${rtCritics}% Crítica\n` : '') +
      `\n¡Hola! Te recomiendo ver este estreno en cartelera. ¿Coordinamos para ir al cine? 🍿\n` +
      `${origin}/?q=${encodeURIComponent(activeMovie.title)}`;

    const url = `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`;
    window.open(url, '_blank');
  };

  // Copiar enlace
  const handleCopyLink = async () => {
    if (!activeMovie) return;
    const origin = typeof window !== 'undefined' ? window.location.origin : 'https://moviesocial.app';
    const shareUrl = `${origin}/?q=${encodeURIComponent(activeMovie.title)}`;
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopiedLink(true);
      setTimeout(() => setCopiedLink(false), 2200);
    } catch {
      alert(shareUrl);
    }
  };

  return (
    <div className="w-full max-w-[1780px] mx-auto px-4 sm:px-8 lg:px-12 xl:px-16 flex flex-col justify-between min-h-[calc(100vh-5rem)] py-3 sm:py-5">
      
      {/* ============================================================== */}
      {/* 1. SECCIÓN PRINCIPAL: ESCENARIO DE ESTRENO (1080P PROPORCIONAL) */}
      {/* ============================================================== */}
      <section className="flex flex-col justify-between flex-grow gap-4">
        
        {/* Cabecera sutil de cartelera */}
        <div className="flex items-center justify-between gap-3 pb-2.5 border-b border-cinema-border/50 flex-shrink-0">
          <div className="flex items-center gap-2.5">
            <span className="flex items-center gap-2 px-3.5 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 font-mono text-xs font-bold shadow-sm">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
              <span>EN SALAS DE CINE</span>
            </span>
            <span className="text-xs sm:text-sm text-cinema-textMuted font-mono">
              {activeLocation.country} • Cartelera Oficial
            </span>
          </div>

          <span className="text-xs font-mono text-cinema-textMuted hidden sm:inline">
            Desliza o usa flechas ← → para cambiar de estreno
          </span>
        </div>

        {/* ESCENARIO DE ESTRENO: MUBI / APPLE TV+ SPLIT HORIZONTAL */}
        {loading ? (
          <div className="flex items-center justify-center my-auto py-16">
            <div className="w-full max-w-5xl h-[58vh] rounded-3xl bg-cinema-card border border-cinema-border animate-pulse shadow-2xl" />
          </div>
        ) : activeMovie ? (
          <div
            onWheel={handleWheelLoop}
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
            className="relative flex flex-col justify-between my-auto flex-grow gap-4 overflow-hidden select-none py-2"
          >
            {/* Resplandor Ambiental Cinematográfico de Gran Escala */}
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-0">
              <img
                src={activeMovie.backdropURL || activeMovie.posterURL}
                alt=""
                className="w-[1500px] h-[680px] object-cover rounded-full blur-[170px] opacity-30 filter brightness-110 transition-all duration-700"
              />
            </div>

            {/* ESCENARIO PRINCIPAL: SPLIT HORIZONTAL 2 COLUMNAS (1080P) */}
            <div className="relative z-10 grid grid-cols-1 md:grid-cols-12 gap-8 lg:gap-14 xl:gap-20 items-center my-auto w-full px-2 sm:px-6">
              
              {/* COLUMNA IZQUIERDA: AFICHE TEATRAL IMPONENTE (5 COLS) */}
              {/* 'Ver Ficha Cinéfila' aparece ÚNICAMENTE al hacer hover sobre este elemento de contexto */}
              <div className="md:col-span-5 flex flex-col items-center justify-center">
                <div
                  onClick={() => onSelectMovie(activeMovie)}
                  className="relative group/poster cursor-pointer h-[48vh] sm:h-[56vh] md:h-[62vh] lg:h-[70vh] max-h-[620px] aspect-[2/3] rounded-3xl overflow-hidden border-2 border-cinema-gold/80 shadow-[0_30px_90px_-10px_rgba(0,0,0,0.98),0_0_60px_-10px_rgba(229,169,60,0.3)] ring-2 ring-black/80 transition-all duration-500 transform hover:scale-[1.02]"
                >
                  <img
                    src={activeMovie.posterURL}
                    alt={activeMovie.title}
                    className="w-full h-full object-cover filter brightness-100 group-hover/poster:brightness-105 transition-all duration-500"
                  />
                  {/* Hover Interactivo: Solo en el Afiche */}
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover/poster:opacity-100 transition-opacity duration-300 bg-black/50 backdrop-blur-[2px]">
                    <span className="px-6 py-3 rounded-2xl bg-gradient-to-r from-amber-500 to-cinema-gold text-black font-black text-xs sm:text-sm tracking-wide shadow-2xl flex items-center gap-2.5 transform scale-95 group-hover/poster:scale-100 transition-transform">
                      <Clapperboard className="w-4 h-4" />
                      <span>Ver Ficha Cinéfila</span>
                    </span>
                  </div>
                </div>
              </div>

              {/* COLUMNA DERECHA: EDICIÓN CINÉFILA & ACCIONES (7 COLS) */}
              <div className="md:col-span-7 flex flex-col justify-center text-left gap-4 sm:gap-5 max-w-3xl">
                
                {/* Spotlight Tagline si existe */}
                {isSpotlight && spotlight?.tagline && (
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-amber-300 font-sans font-semibold flex items-center gap-1.5 text-xs bg-amber-500/10 px-3 py-1 rounded-full border border-amber-500/25">
                      <Award className="w-3.5 h-3.5 text-cinema-gold" />
                      {spotlight.tagline}
                    </span>
                  </div>
                )}

                {/* Título de la Película (Clickeable con cursor-pointer y hover) */}
                <h1
                  onClick={() => onSelectMovie(activeMovie)}
                  className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-black text-white tracking-tight uppercase leading-none line-clamp-2 cursor-pointer hover:text-cinema-gold transition-colors"
                >
                  {activeMovie.title}
                </h1>

                {/* Metadatos Principales */}
                <div className="flex flex-wrap items-center gap-2.5 text-xs sm:text-base text-gray-300 font-medium">
                  {activeMovie.director && (
                    <>
                      <span className="text-white font-bold">Dirección: {activeMovie.director}</span>
                      <span className="text-cinema-border">•</span>
                    </>
                  )}
                  <span className="font-mono text-cinema-textMuted">{activeMovie.releaseYear}</span>
                  <span className="text-cinema-border">•</span>
                  <span className="text-cinema-gold font-mono font-bold flex items-center gap-1.5">
                    <Clock className="w-4 h-4" />
                    {formatDuration(activeMovie.runtimeMinutes)}
                  </span>
                  {activeMovie.productionCompany && (
                    <>
                      <span className="text-cinema-border">•</span>
                      <span className="text-gray-400 font-medium">{activeMovie.productionCompany}</span>
                    </>
                  )}
                </div>

                {/* Categorías Temáticas (Sin hashtag) */}
                <div className="flex items-center gap-2 flex-wrap pt-0.5">
                  {(activeMovie.genres || ['Cine de Autor']).slice(0, 4).map((g) => (
                    <span
                      key={g}
                      className="px-3.5 py-1 rounded-full bg-white/5 border border-white/10 hover:border-cinema-gold/40 text-cinema-gold text-xs font-semibold tracking-wide transition-colors"
                    >
                      {g}
                    </span>
                  ))}
                </div>

                {/* Sinopsis de Impacto (Clickeable) */}
                <p
                  onClick={() => onSelectMovie(activeMovie)}
                  className="text-sm sm:text-base text-gray-200/90 leading-relaxed line-clamp-3 font-normal max-w-2xl cursor-pointer hover:text-white transition-colors"
                >
                  {activeMovie.overview || 'Una de las propuestas más esperadas de la cartelera de autor de esta temporada.'}
                </p>

                {/* MATRIZ DE CALIFICACIONES OFICIALES */}
                <div className="flex items-center gap-3 sm:gap-4 flex-wrap pt-1">
                  {/* MovieScore Oficial */}
                  <div
                    title="MovieScore Oficial (Ponderado de Crítica y Audiencia)"
                    className="flex items-center gap-2.5 py-2 px-4 rounded-2xl bg-amber-500/15 border border-cinema-gold/50 text-cinema-gold shadow-md"
                  >
                    <Sparkles className="w-5 h-5 fill-cinema-gold flex-shrink-0" />
                    <div className="flex flex-col leading-none">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-cinema-gold/80">MovieScore</span>
                      <span className="font-mono font-black text-lg sm:text-xl text-white">{compositeScore.toFixed(1)}</span>
                    </div>
                  </div>

                  {/* Tomatometer */}
                  <div
                    title={`Tomatometer: ${rtCritics ?? 'N/A'}% Crítica`}
                    className="flex items-center gap-2 py-2 px-3.5 rounded-2xl bg-white/5 border border-white/10 text-cinema-textSecondary"
                  >
                    <span className="text-base">🍅</span>
                    <div className="flex flex-col leading-none">
                      <span className="text-[10px] uppercase font-bold text-cinema-textMuted">Crítica</span>
                      <span className="font-mono font-bold text-sm text-white">{rtCritics != null ? `${rtCritics}%` : '-'}</span>
                    </div>
                  </div>

                  {/* Popcornmeter */}
                  <div
                    title={`Popcornmeter: ${rtAudience ?? 'N/A'}% Audiencia`}
                    className="flex items-center gap-2 py-2 px-3.5 rounded-2xl bg-white/5 border border-white/10 text-cinema-textSecondary"
                  >
                    <span className="text-base">🍿</span>
                    <div className="flex flex-col leading-none">
                      <span className="text-[10px] uppercase font-bold text-cinema-textMuted">Audiencia</span>
                      <span className="font-mono font-bold text-sm text-white">{rtAudience != null ? `${rtAudience}%` : '-'}</span>
                    </div>
                  </div>

                  {/* IMDb */}
                  <div
                    title={`IMDb: ${imdbScore ? imdbScore.toFixed(1) : 'N/A'}/10`}
                    className="flex items-center gap-2 py-2 px-3.5 rounded-2xl bg-white/5 border border-white/10 text-cinema-textSecondary"
                  >
                    <span className="text-[10px] bg-cinema-imdb text-black px-1.5 rounded font-black font-sans leading-none py-0.5">IMDb</span>
                    <div className="flex flex-col leading-none">
                      <span className="text-[10px] uppercase font-bold text-cinema-textMuted">Puntuación</span>
                      <span className="font-mono font-bold text-sm text-white">{imdbScore != null ? `${imdbScore.toFixed(1)}/10` : '-'}</span>
                    </div>
                  </div>
                </div>

                {/* ACCIONES PRINCIPALES: BOTÓN VER FICHA + GUARDAR + TRÁILER Y COMPARTIR */}
                <div className="flex items-center gap-3 pt-2.5 flex-wrap">
                  {/* Botón Principal: Ver Ficha Cinéfila (Directo y Destacado) */}
                  <button
                    onClick={() => onSelectMovie(activeMovie)}
                    className="px-5 py-3 rounded-2xl bg-gradient-to-r from-amber-500 to-cinema-gold hover:from-amber-400 hover:to-amber-500 text-black font-black text-xs sm:text-sm flex items-center gap-2 shadow-xl shadow-amber-950/40 transition-all hover:scale-105 active:scale-95"
                    title="Abrir la ficha cinéfila completa con calificaciones y reparto"
                  >
                    <Clapperboard className="w-4 h-4" />
                    <span>Ver Ficha Cinéfila</span>
                  </button>

                  {/* Botón 2: Guardar en Watchlist */}
                  <button
                    onClick={handleToggleWatchlist}
                    disabled={savingWatchlist}
                    className={`px-5 py-3 rounded-2xl font-bold text-xs sm:text-sm transition-all hover:scale-105 active:scale-95 flex items-center gap-2.5 shadow-xl ${
                      isInWatchlist
                        ? 'bg-amber-500/25 text-cinema-gold border-2 border-cinema-gold/70 shadow-amber-950/50'
                        : 'bg-cinema-surface hover:bg-cinema-card border border-cinema-border hover:border-cinema-gold/40 text-white'
                    }`}
                    title="Guardar en tu Watchlist personal"
                  >
                    {isInWatchlist ? (
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

                  {/* Botón 3: Tráiler Oficial en YouTube (Solo Icono) */}
                  {activeMovie.trailer && (
                    <a
                      href={activeMovie.trailer.youtubeUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 sm:p-3.5 rounded-2xl bg-red-600 hover:bg-red-500 text-white shadow-xl shadow-red-950/50 transition-all hover:scale-110 active:scale-95 flex items-center justify-center flex-shrink-0"
                      title={`Ver tráiler oficial en la App de YouTube (${activeMovie.trailer.languageLabel})`}
                    >
                      <YouTubeIcon className="w-5 h-5 text-white" />
                    </a>
                  )}

                  {/* Botón 4: Compartir (Solo Icono) */}
                  <button
                    onClick={handleOpenShareModal}
                    className="p-3 sm:p-3.5 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-400 hover:from-emerald-400 hover:to-teal-300 text-black shadow-xl shadow-emerald-950/50 transition-all hover:scale-110 active:scale-95 flex items-center justify-center flex-shrink-0"
                    title="Compartir por WhatsApp o Chat interno"
                  >
                    <Share2 className="w-5 h-5 text-black" />
                  </button>
                </div>
              </div>
            </div>

            {/* ============================================================== */}
            {/* BANDA INFERIOR: CARRETE DE ESTRENOS CENTRADO HORIZONTALMENTE    */}
            {/* Solo rota y cambia la película activa; NO muestra ficha hover   */}
            {/* ============================================================== */}
            <div
              onWheel={handleWheelLoop}
              onTouchStart={handleReelTouchStart}
              onTouchEnd={handleReelTouchEnd}
              className="flex-shrink-0 pt-3 pb-1 border-t border-cinema-border/50"
            >
              <div className="flex items-center justify-between mb-2 px-1 max-w-4xl mx-auto">
                <span className="text-xs font-bold uppercase tracking-wider text-cinema-textMuted flex items-center gap-2">
                  <Film className="w-3.5 h-3.5 text-cinema-gold" />
                  Estrenos en Cartelera
                </span>
                <div className="flex items-center gap-1.5">
                  <button
                    onClick={goToPrev}
                    className="p-1.5 rounded-lg bg-cinema-card hover:bg-cinema-surface border border-cinema-border text-cinema-textMuted hover:text-white transition-colors"
                    title="Estreno anterior"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>
                  <button
                    onClick={goToNext}
                    className="p-1.5 rounded-lg bg-cinema-card hover:bg-cinema-surface border border-cinema-border text-cinema-textMuted hover:text-white transition-colors"
                    title="Siguiente estreno"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Riel de Miniaturas Pequeñas CENTRADAS (justify-center) */}
              <div className="w-full flex items-center justify-center overflow-hidden">
                <div
                  ref={reelContainerRef}
                  className="flex items-center justify-center gap-2 sm:gap-2.5 overflow-x-auto py-1 scrollbar-none scroll-smooth max-w-full"
                >
                  {movies.map((m, idx) => {
                    const isActive = idx === activeIdx;
                    return (
                      <button
                        key={m.id}
                        ref={isActive ? activeThumbRef : null}
                        onClick={() => setActiveIdx(idx)}
                        className={`relative flex-shrink-0 w-14 sm:w-16 md:w-20 aspect-[2/3] rounded-xl overflow-hidden transition-all duration-300 text-left ${
                          isActive
                            ? 'ring-2 ring-cinema-gold scale-105 shadow-[0_4px_20px_rgba(229,169,60,0.4)] z-10'
                            : 'opacity-50 hover:opacity-90 filter grayscale-[20%] hover:grayscale-0'
                        }`}
                        title={`${m.title} (${m.releaseYear})`}
                      >
                        <img src={m.posterURL} alt={m.title} className="w-full h-full object-cover" />
                        <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-transparent to-transparent flex flex-col justify-end p-1">
                          <span className="text-[9px] text-cinema-gold font-mono font-bold leading-none">
                            ★ {m.ratings.compositeScore?.toFixed(1) || 'N/A'}
                          </span>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

          </div>
        ) : null}
      </section>

      {/* ============================================================== */}
      {/* MODAL MULTICANAL PARA COMPARTIR (WHATSAPP + CHATS)             */}
      {/* ============================================================== */}
      {isShareModalOpen && activeMovie && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="relative w-full max-w-md rounded-3xl bg-cinema-bg border border-cinema-border shadow-2xl p-6 flex flex-col gap-5">
            {/* Cabecera */}
            <div className="flex items-center justify-between border-b border-cinema-border pb-3">
              <div className="flex items-center gap-2">
                <Share2 className="w-4 h-4 text-cinema-gold" />
                <h3 className="text-sm font-bold text-white uppercase tracking-wider">
                  Compartir Estreno
                </h3>
              </div>
              <button
                onClick={() => setIsShareModalOpen(false)}
                className="p-1.5 rounded-full hover:bg-white/10 text-cinema-textMuted hover:text-white"
              >
                ✕
              </button>
            </div>

            {/* Película a compartir */}
            <div className="flex items-center gap-3 p-3 rounded-2xl bg-cinema-card border border-cinema-border">
              <img
                src={activeMovie.posterURL}
                alt={activeMovie.title}
                className="w-12 h-16 rounded-xl object-cover flex-shrink-0 border border-cinema-border"
              />
              <div className="flex flex-col leading-tight min-w-0">
                <span className="text-sm font-bold text-white truncate">{activeMovie.title}</span>
                <span className="text-xs text-cinema-textSecondary font-mono">{activeMovie.releaseYear}</span>
                <span className="text-xs text-cinema-gold font-mono font-bold mt-1">
                  ★ MovieScore {compositeScore.toFixed(1)} / 10
                </span>
              </div>
            </div>

            {/* OPCIÓN 1: WHATSAPP DIRECTO */}
            <button
              onClick={() => {
                handleShareWhatsApp();
                setIsShareModalOpen(false);
              }}
              className="w-full py-3 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-400 hover:from-emerald-400 hover:to-teal-300 text-black font-black text-sm flex items-center justify-center gap-2.5 shadow-lg shadow-emerald-950/40 transition-transform hover:scale-105 active:scale-95"
            >
              <WhatsAppIcon className="w-5 h-5 text-black" />
              <span>Enviar por WhatsApp</span>
            </button>

            {/* OPCIÓN 2: COPIAR ENLACE */}
            <button
              onClick={handleCopyLink}
              className="w-full py-3 rounded-2xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border hover:border-cinema-gold/40 text-white font-bold text-xs flex items-center justify-center gap-2 transition-colors"
            >
              {copiedLink ? (
                <>
                  <Check className="w-4 h-4 text-emerald-400" />
                  <span className="text-emerald-400 font-bold">¡Enlace copiado al portapapeles!</span>
                </>
              ) : (
                <>
                  <Copy className="w-4 h-4 text-cinema-gold" />
                  <span>Copiar Enlace de Cartelera</span>
                </>
              )}
            </button>

            {/* OPCIÓN 3: CHAT CON AMIGOS DE MOVIESOCIAL */}
            {currentUser && friendsList.length > 0 && (
              <div className="flex flex-col gap-2 pt-2 border-t border-cinema-border">
                <span className="text-xs font-bold text-cinema-textMuted uppercase tracking-wider">
                  O envía por chat interno a un amigo:
                </span>
                <div className="max-h-40 overflow-y-auto flex flex-col gap-1.5 pr-1">
                  {friendsList.map((f) => (
                    <button
                      key={f.id}
                      onClick={async () => {
                        setSendingChatShare(true);
                        try {
                          await fetch('/api/chats/direct', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                              senderId: currentUser.id,
                              receiverId: f.id,
                              initialMessage: `🎬 ¡Te recomiendo ver "${activeMovie.title}" (${activeMovie.releaseYear}) en cartelera! MovieScore: ${compositeScore.toFixed(1)}/10 🍿`,
                              sharedMovieId: activeMovie.id,
                              sharedMovieTitle: activeMovie.title,
                              sharedMoviePosterUrl: activeMovie.posterURL,
                              sharedMovieScore: compositeScore,
                            }),
                          });
                          setIsShareModalOpen(false);
                          onOpenChatWithFriend?.(f);
                        } catch (e) {
                          alert('Error enviando al chat');
                        } finally {
                          setSendingChatShare(false);
                        }
                      }}
                      disabled={sendingChatShare}
                      className="p-2 rounded-xl bg-cinema-card hover:bg-cinema-surface border border-cinema-border flex items-center justify-between text-left transition-colors"
                    >
                      <div className="flex items-center gap-2">
                        <img
                          src={f.avatarUrl}
                          alt={f.displayName}
                          className="w-7 h-7 rounded-full object-cover"
                        />
                        <span className="text-xs font-bold text-white">{f.displayName}</span>
                      </div>
                      <Send className="w-3.5 h-3.5 text-cinema-gold" />
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

    </div>
  );
};
