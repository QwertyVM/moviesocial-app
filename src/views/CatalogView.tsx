"use client";

import React, { useState, useEffect, useRef } from 'react';
import { Movie, User, UserLocation, Friend, calculateCompositeScore } from '../types';
import { api } from '../services/api';
import { CinephileSpotlightData } from '@/actions/movies';
import {
  Film,
  Sparkles,
  Search,
  Clapperboard,
  Award,
  ChevronLeft,
  ChevronRight,
  Clock,
  Share2,
  Bookmark,
  BookmarkCheck,
  MessageSquare,
  UserPlus,
  X,
  Send,
  Check,
  Copy,
  ExternalLink,
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
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Índice del estreno principal enfocado en la Gran Cartelera
  const [activeIdx, setActiveIdx] = useState<number>(0);

  // Watchlist de usuario
  const [watchlistIds, setWatchlistIds] = useState<string[]>([]);
  const [savingWatchlist, setSavingWatchlist] = useState(false);

  // Modal para compartir (WhatsApp + Chat Interno + Enlace)
  const [isShareModalOpen, setIsShareModalOpen] = useState(false);
  const [friendsList, setFriendsList] = useState<Friend[]>([]);
  const [friendSearch, setFriendSearch] = useState('');
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

  // Cargar estrictamente películas de Estreno en Cartelera (100% Estrenos)
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

  // Filtrado reactivo en vivo si el usuario busca por título sin salir de la experiencia teatral
  const filteredMovies = searchQuery.trim()
    ? movies.filter(
        (m) =>
          m.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          m.director?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          m.genres.some((g) => g.toLowerCase().includes(searchQuery.toLowerCase()))
      )
    : movies;

  const n = filteredMovies.length;
  const activeMovie = n > 0 ? filteredMovies[Math.min(activeIdx, n - 1)] : null;
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

  // Auto-scroll del carrete inferior hacia el afiche activo
  useEffect(() => {
    if (activeThumbRef.current) {
      activeThumbRef.current.scrollIntoView({
        behavior: 'smooth',
        inline: 'center',
        block: 'nearest',
      });
    }
  }, [activeIdx]);

  // Rotación con rueda del ratón en bucle infinito (con debounce)
  const handleWheelLoop = (e: React.WheelEvent) => {
    const now = Date.now();
    if (now - lastWheelTime.current < 160) return;
    if (Math.abs(e.deltaY) > 12 || Math.abs(e.deltaX) > 12) {
      if (e.deltaY > 0 || e.deltaX > 0) {
        goToNext();
      } else {
        goToPrev();
      }
      lastWheelTime.current = now;
    }
  };

  // Swipe táctil en el escenario principal
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

  // Atajos de teclado (Flechas izquierda y derecha)
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
  const rtAudience = activeMovie
    ? activeMovie.ratings.rottenTomatoesAudience ?? (compositeScore > 0 ? Math.min(100, Math.round(compositeScore * 10 + 2)) : null)
    : null;
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

  // Compartir por WhatsApp (usando API universal compatible con Web y Móvil)
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

  // Compartir nativo o copiar enlace con feedback
  const handleCopyOrWebShare = async () => {
    if (!activeMovie) return;
    const origin = typeof window !== 'undefined' ? window.location.origin : 'https://moviesocial.app';
    const shareUrl = `${origin}/?q=${encodeURIComponent(activeMovie.title)}`;

    if (typeof navigator !== 'undefined' && navigator.share) {
      try {
        await navigator.share({
          title: activeMovie.title,
          text: `Te recomiendo ver "${activeMovie.title}" (MovieScore: ${compositeScore.toFixed(1)}/10) en MovieSocial 🎬`,
          url: shareUrl,
        });
        return;
      } catch {}
    }

    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopiedLink(true);
      setTimeout(() => setCopiedLink(false), 2500);
    } catch {
      alert(`Enlace: ${shareUrl}`);
    }
  };

  // Enviar recomendación al chat interno de un amigo
  const handleSendChatToFriend = async (friend: Friend) => {
    if (!activeMovie || sendingChatShare) return;
    setSendingChatShare(true);
    try {
      const convo = await api.getOrCreateDirectConversation(friend);
      await api.sendDirectMessage(convo.id, {
        text: `¡Hola! Te recomiendo ver este estreno de cartelera: "${activeMovie.title}". ¿Coordinamos para ir al cine?`,
        messageType: 'movie',
        sharedMovie: activeMovie,
        recipientId: friend.id,
      });
      setIsShareModalOpen(false);
      onOpenChatWithFriend?.(friend);
    } catch (err: any) {
      alert(err.message || 'Error al enviar recomendación en chat');
    } finally {
      setSendingChatShare(false);
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-[calc(100vh-4.25rem)] overflow-hidden flex flex-col justify-between py-2 sm:py-3">
      
      {/* ============================================================== */}
      {/* 1. CABECERA LIMPIA: 100% CARTELERA DE ESTRENOS EN SALAS         */}
      {/* ============================================================== */}
      <div className="flex items-center justify-between gap-3 pb-2 border-b border-cinema-border/60 flex-shrink-0">
        <div className="flex items-center gap-2.5">
          <span className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 font-mono text-[11px] font-bold">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
            <span>EN SALAS DE CINE</span>
          </span>
          <span className="text-xs text-cinema-textMuted hidden sm:inline font-mono">
            Cartelera Oficial
          </span>
        </div>

        {/* Buscador Rápido de Estrenos */}
        <div className="relative w-full sm:w-72">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-cinema-textMuted" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setActiveIdx(0);
            }}
            placeholder="Filtrar estrenos de hoy..."
            className="w-full pl-9 pr-7 py-1.5 sm:py-2 rounded-xl bg-cinema-card border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none transition-colors shadow-inner"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs text-cinema-textMuted hover:text-white"
            >
              ✕
            </button>
          )}
        </div>
      </div>

      {/* ============================================================== */}
      {/* 2. ESCENARIO DE ESTRENO: MUBI / APPLE TV+ SPLIT HORIZONTAL     */}
      {/* ============================================================== */}
      {loading ? (
        <div className="flex items-center justify-center my-auto py-12">
          <div className="w-full max-w-4xl h-[50vh] rounded-3xl bg-cinema-card border border-cinema-border animate-pulse shadow-2xl" />
        </div>
      ) : activeMovie ? (
        <div
          onWheel={handleWheelLoop}
          onTouchStart={handleTouchStart}
          onTouchEnd={handleTouchEnd}
          className="relative flex flex-col justify-between my-auto flex-grow gap-2 sm:gap-4 overflow-hidden select-none py-1"
        >
          {/* Resplandor Ambiental Cinematográfico */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-0">
            <img
              src={activeMovie.backdropURL || activeMovie.posterURL}
              alt=""
              className="w-[1250px] h-[580px] object-cover rounded-full blur-[150px] opacity-25 filter brightness-110 transition-all duration-700"
            />
          </div>

          {/* ESCENARIO PRINCIPAL: SPLIT HORIZONTAL 2 COLUMNAS */}
          <div className="relative z-10 grid grid-cols-1 md:grid-cols-12 gap-6 lg:gap-12 items-center my-auto w-full px-2 sm:px-6">
            
            {/* COLUMNA IZQUIERDA: AFICHE TEATRAL IMPONENTE (5 COLS) */}
            <div className="md:col-span-5 flex flex-col items-center justify-center">
              <div
                onClick={() => onSelectMovie(activeMovie)}
                className="relative h-[44vh] sm:h-[50vh] md:h-[56vh] lg:h-[60vh] max-h-[520px] aspect-[2/3] rounded-3xl overflow-hidden border-2 border-cinema-gold/75 shadow-[0_25px_80px_-10px_rgba(0,0,0,0.98),0_0_50px_-10px_rgba(229,169,60,0.25)] ring-2 ring-black/80 cursor-pointer group transition-all duration-500 transform hover:scale-[1.02]"
              >
                <img
                  src={activeMovie.posterURL}
                  alt={activeMovie.title}
                  className="w-full h-full object-cover filter brightness-100 group-hover:brightness-105 transition-all duration-500"
                />
                {/* Hover Interactivo */}
                <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black/50 backdrop-blur-[2px]">
                  <span className="px-5 py-2.5 rounded-2xl bg-gradient-to-r from-amber-500 to-cinema-gold text-black font-black text-xs tracking-wide shadow-2xl flex items-center gap-2">
                    <Clapperboard className="w-4 h-4" />
                    <span>Ver Ficha Cinéfila</span>
                  </span>
                </div>
              </div>
            </div>

            {/* COLUMNA DERECHA: EDICIÓN CINÉFILA & ACCIONES SOCIALES (7 COLS) */}
            <div className="md:col-span-7 flex flex-col justify-center text-left gap-3 sm:gap-4 max-w-2xl">
              {/* Micro-Header opcional si hay spotlight */}
              {isSpotlight && spotlight?.tagline && (
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-amber-300 font-sans font-semibold flex items-center gap-1 text-[10px] bg-amber-500/10 px-2.5 py-0.5 rounded-full border border-amber-500/20">
                    <Award className="w-3 h-3 text-cinema-gold" />
                    {spotlight.tagline}
                  </span>
                </div>
              )}

              {/* Título de la Película */}
              <h1 className="text-2xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight uppercase leading-none line-clamp-2">
                {activeMovie.title}
              </h1>

              {/* Dirección y Metadatos */}
              <div className="flex flex-wrap items-center gap-2 text-xs text-cinema-textSecondary font-medium">
                {activeMovie.director && (
                  <>
                    <span className="text-white font-semibold">Dirección: {activeMovie.director}</span>
                    <span className="text-cinema-border">•</span>
                  </>
                )}
                <span className="font-mono text-cinema-textMuted">{activeMovie.releaseYear}</span>
                <span className="text-cinema-border">•</span>
                <span className="text-cinema-gold font-mono font-bold flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5" />
                  {formatDuration(activeMovie.runtimeMinutes)}
                </span>
                <span className="text-cinema-border">•</span>
                <div className="inline-flex items-center gap-1.5 flex-wrap">
                  {(activeMovie.genres?.slice(0, 3) || ['Cine']).map((g) => (
                    <span
                      key={g}
                      className="px-2 py-0.5 rounded-md bg-white/5 border border-white/10 text-cinema-gold font-mono text-[11px] font-semibold"
                    >
                      #{g}
                    </span>
                  ))}
                </div>
              </div>

              {/* Sinopsis de Impacto */}
              <p className="text-xs sm:text-sm text-gray-300/90 leading-relaxed line-clamp-3 font-normal">
                {activeMovie.overview || 'Una de las propuestas más esperadas de la cartelera de autor de esta temporada.'}
              </p>

              {/* MATRIZ DE CALIFICACIONES OFICIALES */}
              <div className="flex items-center gap-2 sm:gap-3 flex-wrap pt-1">
                {/* MovieScore Oficial */}
                <div
                  title="MovieScore Oficial (50% IMDb + 30% RT Crítica + 20% RT Audiencia)"
                  className="flex items-center gap-2 py-1.5 px-3.5 rounded-xl bg-amber-500/15 border border-cinema-gold/50 text-cinema-gold shadow-md"
                >
                  <Sparkles className="w-4 h-4 fill-cinema-gold flex-shrink-0" />
                  <div className="flex flex-col leading-none">
                    <span className="text-[9px] font-bold uppercase tracking-wider text-cinema-gold/80">MovieScore</span>
                    <span className="font-mono font-black text-base text-white">{compositeScore.toFixed(1)}</span>
                  </div>
                </div>

                {/* Tomatometer */}
                <div
                  title={`Tomatometer: ${rtCritics ?? 'N/A'}% Crítica`}
                  className="flex items-center gap-1.5 py-1.5 px-3 rounded-xl bg-white/5 border border-white/10 text-cinema-textSecondary"
                >
                  <span className="text-sm">🍅</span>
                  <div className="flex flex-col leading-none">
                    <span className="text-[9px] uppercase font-bold text-cinema-textMuted">Tomatometer</span>
                    <span className="font-mono font-bold text-xs text-white">{rtCritics != null ? `${rtCritics}%` : '-'}</span>
                  </div>
                </div>

                {/* Popcornmeter */}
                <div
                  title={`Popcornmeter: ${rtAudience ?? 'N/A'}% Audiencia`}
                  className="flex items-center gap-1.5 py-1.5 px-3 rounded-xl bg-white/5 border border-white/10 text-cinema-textSecondary"
                >
                  <span className="text-sm">🍿</span>
                  <div className="flex flex-col leading-none">
                    <span className="text-[9px] uppercase font-bold text-cinema-textMuted">Audiencia</span>
                    <span className="font-mono font-bold text-xs text-white">{rtAudience != null ? `${rtAudience}%` : '-'}</span>
                  </div>
                </div>

                {/* IMDb */}
                <div
                  title={`IMDb: ${imdbScore ? imdbScore.toFixed(1) : 'N/A'}/10`}
                  className="flex items-center gap-1.5 py-1.5 px-3 rounded-xl bg-white/5 border border-white/10 text-cinema-textSecondary"
                >
                  <span className="text-[9px] bg-cinema-imdb text-black px-1 rounded font-black font-sans leading-none py-0.5">IMDb</span>
                  <div className="flex flex-col leading-none">
                    <span className="text-[9px] uppercase font-bold text-cinema-textMuted">Puntuación</span>
                    <span className="font-mono font-bold text-xs text-white">{imdbScore != null ? `${imdbScore.toFixed(1)}/10` : '-'}</span>
                  </div>
                </div>
              </div>

              {/* ACCIONES PRINCIPALES (CTA: COMPARTIR + WATCHLIST + FICHA) */}
              <div className="flex items-center gap-2.5 sm:gap-3 pt-2 flex-wrap">
                {/* Botón 1: Compartir Multicanal (con WhatsApp y Chat) */}
                <button
                  onClick={handleOpenShareModal}
                  className="px-4 sm:px-5 py-2.5 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-400 hover:from-emerald-400 hover:to-teal-300 text-black font-black text-xs sm:text-sm shadow-xl shadow-emerald-950/40 transition-all hover:scale-105 active:scale-95 flex items-center gap-2"
                >
                  <Share2 className="w-4 h-4 text-black" />
                  <span>Compartir</span>
                  <WhatsAppIcon className="w-3.5 h-3.5 text-black ml-0.5" />
                </button>

                {/* Botón 2: Watchlist / Quiero Verla */}
                <button
                  onClick={handleToggleWatchlist}
                  disabled={savingWatchlist}
                  className={`px-4 py-2.5 rounded-xl font-bold text-xs sm:text-sm transition-all hover:scale-105 active:scale-95 flex items-center gap-2 shadow ${
                    isInWatchlist
                      ? 'bg-amber-500/20 text-cinema-gold border border-cinema-gold/60 shadow-amber-950/40'
                      : 'bg-cinema-surface hover:bg-cinema-card border border-cinema-border text-white'
                  }`}
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

                {/* Botón 3: Tráiler Oficial en YouTube */}
                {activeMovie.trailer && (
                  <a
                    href={activeMovie.trailer.youtubeUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-4 py-2.5 rounded-xl bg-red-600/90 hover:bg-red-600 text-white font-bold text-xs sm:text-sm transition-all hover:scale-105 active:scale-95 flex items-center gap-2 shadow-lg shadow-red-950/40"
                    title={`Ver tráiler oficial en la app de YouTube (${activeMovie.trailer.languageLabel})`}
                  >
                    <YouTubeIcon className="w-4 h-4 text-white" />
                    <span>Tráiler</span>
                    <span className="text-[10px] px-1.5 py-0.2 rounded bg-black/40 font-mono hidden sm:inline">
                      {activeMovie.trailer.languageLabel}
                    </span>
                  </a>
                )}

                {/* Botón 4: Ver Ficha Cinéfila & Reseñas */}
                <button
                  onClick={() => onSelectMovie(activeMovie)}
                  className="px-4 py-2.5 rounded-xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border hover:border-cinema-gold/50 text-white font-bold text-xs sm:text-sm transition-all hover:scale-105 active:scale-95 flex items-center gap-2 shadow"
                >
                  <Film className="w-3.5 h-3.5 text-cinema-gold" />
                  <span>Ficha Cinéfila</span>
                </button>
              </div>
            </div>
          </div>

          {/* BANDA INFERIOR: CARRETE DE ESTRENOS EN CARTELERA CON ROTACIÓN INFINITA */}
          <div
            onWheel={handleWheelLoop}
            onTouchStart={handleReelTouchStart}
            onTouchEnd={handleReelTouchEnd}
            className="flex-shrink-0 pt-2 pb-1 border-t border-cinema-border/50"
          >
            <div className="flex items-center justify-between mb-1.5 px-1">
              <span className="text-[10px] font-bold uppercase tracking-wider text-cinema-textMuted flex items-center gap-1.5">
                <Film className="w-3 h-3 text-cinema-gold" />
                Estrenos en Cartelera • Rota con la rueda o desliza
              </span>
              <div className="flex items-center gap-1">
                <button
                  onClick={goToPrev}
                  className="p-1 rounded-lg bg-cinema-surface hover:bg-cinema-card text-white border border-cinema-border transition-colors"
                  title="Película anterior (bucle)"
                >
                  <ChevronLeft className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={goToNext}
                  className="p-1 rounded-lg bg-cinema-surface hover:bg-cinema-card text-white border border-cinema-border transition-colors"
                  title="Siguiente película (bucle)"
                >
                  <ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

            {/* Tira Horizontal de Afiches Miniatura (Bucle) */}
            <div
              ref={reelContainerRef}
              className="flex items-center gap-2.5 overflow-x-auto pb-1 scrollbar-none select-none scroll-smooth"
            >
              {filteredMovies.map((m, idx) => {
                const isActive = idx === activeIdx;
                const score = calculateCompositeScore(m.ratings);
                return (
                  <button
                    key={m.id}
                    ref={isActive ? activeThumbRef : null}
                    onClick={() => setActiveIdx(idx)}
                    className={`flex-shrink-0 flex items-center gap-2 p-1.5 rounded-xl text-left transition-all ${
                      isActive
                        ? 'bg-cinema-card border-2 border-cinema-gold shadow-lg shadow-black/80 ring-1 ring-amber-500/50 scale-[1.03]'
                        : 'bg-cinema-surface/70 hover:bg-cinema-surface border border-cinema-border/60 opacity-60 hover:opacity-100'
                    }`}
                  >
                    <img
                      src={m.posterURL}
                      alt={m.title}
                      className="w-8 h-12 object-cover rounded-lg border border-black/40 flex-shrink-0"
                    />
                    <div className="flex flex-col min-w-0 pr-1 max-w-[120px]">
                      <span className={`text-[11px] font-bold truncate ${isActive ? 'text-white' : 'text-cinema-textSecondary'}`}>
                        {m.title}
                      </span>
                      <span className="text-[9px] font-mono font-semibold text-cinema-gold">
                        ★ {score.toFixed(1)}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      ) : (
        <div className="p-16 text-center rounded-3xl bg-cinema-card border border-cinema-border flex flex-col items-center justify-center gap-3 shadow-2xl my-auto">
          <Film className="w-12 h-12 text-cinema-gold/60" />
          <h3 className="text-base font-bold text-white">No se encontraron estrenos con ese título</h3>
          <p className="text-xs text-cinema-textMuted max-w-md">
            Prueba buscando por nombre del director o título de la película.
          </p>
          <button
            onClick={() => setSearchQuery('')}
            className="px-4 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-cinema-gold font-bold"
          >
            Ver todos los estrenos
          </button>
        </div>
      )}

      {/* ============================================================== */}
      {/* 3. MODAL COMPARTIR MULTICANAL (WHATSAPP + CHAT AMIGOS + ENLACE) */}
      {/* ============================================================== */}
      {isShareModalOpen && activeMovie && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-4">
            
            {/* Cabecera del Modal */}
            <div className="flex items-center justify-between pb-2 border-b border-cinema-border">
              <div className="flex flex-col">
                <h3 className="text-sm font-bold text-white flex items-center gap-2">
                  <Share2 className="w-4 h-4 text-emerald-400" />
                  Compartir "{activeMovie.title}"
                </h3>
                <span className="text-[11px] text-cinema-textMuted">
                  Recomienda este estreno por WhatsApp o a tus amigos en MovieSocial
                </span>
              </div>
              <button
                onClick={() => setIsShareModalOpen(false)}
                className="text-cinema-textMuted hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Vista Previa de la Tarjeta a Compartir */}
            <div className="p-3 rounded-2xl bg-cinema-surface/80 border border-cinema-border flex items-center gap-3">
              <img
                src={activeMovie.posterURL}
                alt={activeMovie.title}
                className="w-12 h-16 object-cover rounded-xl border border-cinema-border flex-shrink-0"
              />
              <div className="flex flex-col min-w-0 flex-grow">
                <span className="text-xs font-bold text-white truncate">{activeMovie.title}</span>
                <span className="text-[10px] text-cinema-textMuted">
                  {activeMovie.releaseYear} • Dir. {activeMovie.director || 'Cine de Autor'}
                </span>
                <span className="text-[10px] font-mono font-bold text-cinema-gold mt-0.5">
                  MovieScore Oficial: ★ {compositeScore.toFixed(1)} / 10
                </span>
              </div>
            </div>

            {/* Canales Directos: WhatsApp & Copiar Enlace con Iconos SVG Oficiales */}
            <div className="grid grid-cols-2 gap-3 pt-1">
              {/* WhatsApp con botón oficial e icono SVG */}
              <button
                onClick={handleShareWhatsApp}
                className="flex items-center justify-center gap-2 p-3 rounded-2xl bg-[#25D366] hover:bg-[#20ba59] text-black font-extrabold text-xs shadow-lg shadow-emerald-950/40 transition-all hover:scale-105 active:scale-95"
              >
                <WhatsAppIcon className="w-4 h-4 text-black flex-shrink-0" />
                <span>Enviar por WhatsApp</span>
              </button>

              {/* Copiar enlace directo con icono SVG */}
              <button
                onClick={handleCopyOrWebShare}
                className="flex items-center justify-center gap-2 p-3 rounded-2xl bg-cinema-surface hover:bg-cinema-surface/80 border border-cinema-border text-white font-bold text-xs transition-all hover:scale-105 active:scale-95"
              >
                {copiedLink ? (
                  <>
                    <Check className="w-4 h-4 text-emerald-400" />
                    <span className="text-emerald-400 font-bold">¡Copiado!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-4 h-4 text-cinema-gold" />
                    <span>Copiar Enlace</span>
                  </>
                )}
              </button>
            </div>

            {/* División: Chat Interno con Amigos */}
            <div className="pt-2 border-t border-cinema-border/50 flex flex-col gap-2">
              <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-400 flex items-center gap-1">
                <MessageSquare className="w-3.5 h-3.5" /> O enviar en chat privado a un amigo:
              </span>

              {currentUser ? (
                <>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-cinema-textMuted" />
                    <input
                      type="text"
                      value={friendSearch}
                      onChange={(e) => setFriendSearch(e.target.value)}
                      placeholder="Buscar en tus amigos..."
                      className="w-full pl-9 pr-3 py-1.5 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white placeholder-cinema-textMuted outline-none focus:border-cinema-gold"
                    />
                  </div>

                  <div className="max-h-56 overflow-y-auto flex flex-col gap-1.5 pr-1">
                    {friendsList.length > 0 ? (
                      friendsList
                        .filter((f) =>
                          f.displayName.toLowerCase().includes(friendSearch.toLowerCase()) ||
                          f.username.toLowerCase().includes(friendSearch.toLowerCase())
                        )
                        .map((f) => (
                          <button
                            key={f.id}
                            disabled={sendingChatShare}
                            onClick={() => handleSendChatToFriend(f)}
                            className="p-2.5 rounded-xl bg-cinema-surface hover:bg-emerald-500/10 border border-cinema-border hover:border-emerald-500/40 flex items-center justify-between text-left transition-all group disabled:opacity-50"
                          >
                            <div className="flex items-center gap-3">
                              <img
                                src={f.avatarUrl}
                                alt={f.displayName}
                                className="w-8 h-8 rounded-full object-cover border border-cinema-border"
                              />
                              <div className="flex flex-col">
                                <span className="text-xs font-bold text-white group-hover:text-emerald-400 transition-colors">
                                  {f.displayName}
                                </span>
                                <span className="text-[10px] text-cinema-textMuted">{f.username}</span>
                              </div>
                            </div>
                            <span className="text-[11px] font-semibold text-emerald-400 px-2 py-0.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 flex items-center gap-1">
                              <Send className="w-3 h-3" />
                              <span>Enviar</span>
                            </span>
                          </button>
                        ))
                    ) : (
                      <p className="text-xs text-cinema-textMuted italic p-2 text-center">
                        No tienes amigos agregados aún.
                      </p>
                    )}
                  </div>
                </>
              ) : (
                <div className="p-4 rounded-2xl bg-cinema-surface/60 border border-cinema-border text-center flex flex-col items-center gap-2">
                  <UserPlus className="w-6 h-6 text-cinema-textMuted" />
                  <p className="text-xs text-cinema-textSecondary">
                    Inicia sesión para enviar recomendaciones directas a tus amigos en MovieSocial.
                  </p>
                  <button
                    onClick={() => {
                      setIsShareModalOpen(false);
                      onOpenAuthModal?.('login', 'Inicia sesión para chatear con tus amigos.');
                    }}
                    className="px-3.5 py-1.5 rounded-xl bg-cinema-gold text-black font-bold text-xs"
                  >
                    Iniciar Sesión
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
