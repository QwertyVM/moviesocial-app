"use client";

import React, { useState } from 'react';
import { User, UserLocation } from '../../types';
import { Film, Users, MessageSquare, User as UserIcon, MapPin, ChevronDown, Check, Sparkles, Database, Navigation, Lock, LogIn, LogOut, UserPlus, Globe } from 'lucide-react';
import { AVAILABLE_CITIES } from '../../data/curatedMovies';

interface NavbarProps {
  activeTab: 'catalog' | 'archive' | 'feed' | 'chats' | 'profile';
  onSelectTab: (tab: 'catalog' | 'archive' | 'feed' | 'chats' | 'profile') => void;
  currentUser: User | null;
  currentLocation?: UserLocation;
  onSelectCity: (city: UserLocation) => void;
  onOpenSubscriptionModal?: (reason?: string) => void;
  onOpenAuthModal?: (mode: 'login' | 'register') => void;
  onLogout?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  activeTab,
  onSelectTab,
  currentUser,
  currentLocation,
  onSelectCity,
  onOpenSubscriptionModal,
  onOpenAuthModal,
  onLogout,
}) => {
  const [cityDropdownOpen, setCityDropdownOpen] = useState(false);
  const [gpsLoading, setGpsLoading] = useState(false);

  const activeLocation =
    currentLocation ||
    currentUser?.location || {
      city: 'Lima',
      country: 'Perú',
      countryCode: 'PE',
      flagEmoji: '🇵🇪',
      isLocal: true,
      area: 'Lima',
    };

  const handleDetectGPS = () => {
    if (typeof window === 'undefined' || !navigator.geolocation) {
      alert('Tu navegador no soporta geolocalización.');
      return;
    }
    setGpsLoading(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          const { latitude, longitude } = pos.coords;
          const res = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`
          );
          const data = await res.json();
          const city =
            data.address.city ||
            data.address.town ||
            data.address.village ||
            data.address.municipality ||
            data.address.state ||
            'Mi Ciudad';
          const country = data.address.country || 'Mi País';
          const countryCode = (data.address.country_code || 'PE').toUpperCase();

          // Código bandera emoji
          const codePoints = countryCode
            .split('')
            .map((char: string) => 127397 + char.charCodeAt(0));
          const flagEmoji = String.fromCodePoint(...codePoints);

          onSelectCity({
            city,
            country,
            countryCode,
            flagEmoji,
            isLocal: true,
            area: city,
          });
          setCityDropdownOpen(false);
        } catch (err) {
          console.warn('Error en reverse geocoding:', err);
        } finally {
          setGpsLoading(false);
        }
      },
      (err) => {
        console.warn('GPS permiso denegado o error:', err);
        setGpsLoading(false);
      },
      { timeout: 8000 }
    );
  };

  return (
    <>
      {/* Top Header Navbar */}
      <header className="sticky top-0 z-40 w-full border-b border-cinema-border bg-cinema-bg/90 backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
          
          {/* Logo & Brand */}
          <div className="flex items-center gap-6">
            <button
              onClick={() => onSelectTab('catalog')}
              className="flex items-center gap-2.5 group focus:outline-none"
            >
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-amber-600 to-cinema-gold flex items-center justify-center shadow-lg shadow-amber-900/30 group-hover:scale-105 transition-transform">
                <Film className="w-5 h-5 text-black" />
              </div>
              <div className="flex flex-col text-left">
                <span className="font-bold text-lg tracking-tight text-white flex items-center gap-1.5">
                  MovieSocial
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-cinema-border text-cinema-textSecondary font-mono uppercase">
                    Web
                  </span>
                </span>
                <span className="text-[10px] text-cinema-textMuted hidden sm:inline">Cine, Ratings & Amigos</span>
              </div>
            </button>

            {/* City Selector Dropdown */}
            <div className="relative">
              <button
                onClick={() => setCityDropdownOpen(!cityDropdownOpen)}
                className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-cinema-surface hover:bg-cinema-card border border-cinema-border hover:border-cinema-borderHover transition-all text-xs font-medium text-cinema-textPrimary"
                title="Cambiar tu ciudad para consultar salas y horarios"
                suppressHydrationWarning
              >
                <MapPin className="w-3.5 h-3.5 text-cinema-gold" />
                <span className="mr-0.5" suppressHydrationWarning>{activeLocation.flagEmoji}</span>
                <span suppressHydrationWarning>{activeLocation.city}</span>
                <ChevronDown className="w-3.5 h-3.5 text-cinema-textMuted" />
              </button>

              {cityDropdownOpen && (
                <div className="absolute left-0 mt-2 w-64 rounded-xl bg-cinema-card border border-cinema-border shadow-2xl z-50 p-2 max-h-80 overflow-y-auto">
                  {/* Botón GPS */}
                  <button
                    onClick={handleDetectGPS}
                    disabled={gpsLoading}
                    className="w-full mb-2 flex items-center justify-center gap-2 px-3 py-2 rounded-lg bg-cinema-gold/15 hover:bg-cinema-gold/25 border border-cinema-gold/40 text-cinema-gold font-semibold text-xs transition-colors"
                  >
                    <Navigation className={`w-3.5 h-3.5 ${gpsLoading ? 'animate-spin' : ''}`} />
                    <span>{gpsLoading ? 'Detectando GPS...' : 'Detectar mi ubicación (GPS)'}</span>
                  </button>

                  <div className="px-2 py-1 text-[10px] font-semibold text-cinema-textMuted uppercase tracking-wider">
                    O selecciona tu país / ciudad:
                  </div>
                  {AVAILABLE_CITIES.map((loc) => {
                    const isSelected = loc.city === activeLocation.city;
                    return (
                      <button
                        key={loc.city}
                        onClick={() => {
                          onSelectCity(loc);
                          setCityDropdownOpen(false);
                        }}
                        className={`w-full flex items-center justify-between px-3 py-2 text-xs text-left transition-colors ${
                          isSelected
                            ? 'bg-cinema-gold/15 text-cinema-gold font-semibold'
                            : 'text-cinema-textPrimary hover:bg-cinema-surface'
                        }`}
                      >
                        <span className="flex items-center gap-2">
                          <span>{loc.flagEmoji}</span>
                          <span>{loc.city}</span>
                          <span className="text-cinema-textMuted text-[10px]">({loc.country})</span>
                        </span>
                        {isSelected && <Check className="w-3.5 h-3.5 text-cinema-gold" />}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Center Navigation Tabs (Desktop) */}
          <div className="hidden lg:flex items-center gap-3">
            <nav className="flex items-center gap-1 bg-cinema-surface/90 p-1.5 rounded-2xl border border-cinema-border shadow-inner">
              <button
                onClick={() => onSelectTab('catalog')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                  activeTab === 'catalog'
                    ? 'bg-cinema-card text-cinema-gold shadow-lg shadow-black/80 border border-cinema-gold/40'
                    : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
                }`}
              >
                <Film className="w-3.5 h-3.5 text-cinema-gold" />
                <span>Estrenos en Cartelera</span>
              </button>

              <button
                onClick={() => onSelectTab('archive')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                  activeTab === 'archive'
                    ? 'bg-cinema-card text-cinema-gold shadow-lg shadow-black/80 border border-cinema-gold/40'
                    : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
                }`}
              >
                <Globe className="w-3.5 h-3.5 text-cinema-gold" />
                <span>Archivo Mundial</span>
              </button>

              <button
                onClick={() => onSelectTab('feed')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                  activeTab === 'feed'
                    ? 'bg-cinema-card text-cinema-gold shadow-lg shadow-black/80 border border-cinema-gold/40'
                    : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
                }`}
              >
                <Users className="w-3.5 h-3.5 text-indigo-400" />
                <span>La Tertulia</span>
                {!currentUser && <Lock className="w-3 h-3 text-cinema-textMuted/70" />}
              </button>

              <button
                onClick={() => onSelectTab('chats')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                  activeTab === 'chats'
                    ? 'bg-cinema-card text-cinema-gold shadow-lg shadow-black/80 border border-cinema-gold/40'
                    : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
                }`}
              >
                <MessageSquare className="w-3.5 h-3.5 text-emerald-400" />
                <span>Salas & Cineclubs</span>
                {!currentUser && <Lock className="w-3 h-3 text-cinema-textMuted/70" />}
              </button>

              <button
                onClick={() => onSelectTab('profile')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                  activeTab === 'profile'
                    ? 'bg-cinema-card text-cinema-gold shadow-lg shadow-black/80 border border-cinema-gold/40'
                    : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
                }`}
              >
                <UserIcon className="w-3.5 h-3.5 text-amber-400" />
                <span>Mi Filmoteca</span>
                {!currentUser && <Lock className="w-3 h-3 text-cinema-textMuted/70" />}
              </button>
            </nav>
          </div>

          {/* Right Side: Auth / User Pill */}
          <div className="flex items-center gap-2 sm:gap-3">

            {currentUser ? (
              <>
                {/* Subscription status pill */}
                <button
                  onClick={() => onOpenSubscriptionModal?.()}
                  className={`hidden sm:flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold transition-all shadow-sm ${
                    currentUser.isPremium
                      ? 'bg-cinema-gold/15 hover:bg-cinema-gold/25 text-cinema-gold border border-cinema-gold/40'
                      : 'bg-cinema-surface hover:bg-cinema-card text-cinema-textSecondary border border-cinema-border'
                  }`}
                  title={
                    currentUser.isPremium
                      ? 'Suscripción Mensual Activa: Tus comentarios son visibles al mundo'
                      : 'Plan Base: Solo interacción con amigos. Clic para activar suscripción global'
                  }
                >
                  {currentUser.isPremium ? (
                    <>
                      <Sparkles className="w-3.5 h-3.5 text-cinema-gold fill-cinema-gold" />
                      <span>Cinéfilo Pro</span>
                    </>
                  ) : (
                    <>
                      <Users className="w-3.5 h-3.5 text-purple-400" />
                      <span>Plan Base</span>
                      <span className="text-[10px] text-cinema-gold font-bold ml-0.5">Mejorar</span>
                    </>
                  )}
                </button>

                {/* User Profile Pill */}
                <button
                  onClick={() => onSelectTab('profile')}
                  className="flex items-center gap-2.5 p-1 sm:pr-3 rounded-full bg-cinema-surface hover:bg-cinema-card border border-cinema-border transition-colors group"
                >
                  <img
                    src={currentUser.avatarUrl}
                    alt={currentUser.displayName}
                    className="w-8 h-8 rounded-full object-cover border border-cinema-gold/40"
                  />
                  <div className="hidden sm:flex flex-col text-left">
                    <span className="text-xs font-semibold text-white group-hover:text-cinema-gold transition-colors flex items-center gap-1">
                      {currentUser.displayName}
                      {currentUser.isPremium && <Sparkles className="w-3 h-3 text-cinema-gold fill-cinema-gold" />}
                    </span>
                    <span className="text-[10px] text-cinema-textMuted">{currentUser.username}</span>
                  </div>
                </button>

                {/* Logout Button */}
                {onLogout && (
                  <button
                    onClick={onLogout}
                    className="p-2 rounded-xl bg-cinema-surface hover:bg-red-500/15 text-cinema-textMuted hover:text-red-400 border border-cinema-border hover:border-red-500/30 transition-colors"
                    title="Cerrar Sesión"
                  >
                    <LogOut className="w-4 h-4" />
                  </button>
                )}
              </>
            ) : (
              <div className="flex items-center gap-2">
                <button
                  onClick={() => onOpenAuthModal?.('login')}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-cinema-surface hover:bg-cinema-card border border-cinema-border text-xs font-medium text-cinema-textPrimary hover:text-white transition-colors"
                >
                  <LogIn className="w-3.5 h-3.5 text-cinema-gold" />
                  <span>Iniciar Sesión</span>
                </button>

                <button
                  onClick={() => onOpenAuthModal?.('register')}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold shadow-md shadow-amber-900/30 transition-transform hover:scale-105"
                >
                  <UserPlus className="w-3.5 h-3.5" />
                  <span className="hidden sm:inline">Crear Cuenta</span>
                  <span className="sm:hidden">Registro</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Mobile Bottom Navigation Bar */}
      <div className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-cinema-bg/95 border-t border-cinema-border backdrop-blur-xl px-2 py-2 flex items-center justify-around">
        <button
          onClick={() => onSelectTab('catalog')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-semibold transition-colors ${
            activeTab === 'catalog' ? 'text-cinema-gold' : 'text-cinema-textMuted'
          }`}
        >
          <Film className="w-4 h-4" />
          <span>Cartelera</span>
        </button>

        <button
          onClick={() => onSelectTab('archive')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-semibold transition-colors ${
            activeTab === 'archive' ? 'text-cinema-gold' : 'text-cinema-textMuted'
          }`}
        >
          <Globe className="w-4 h-4" />
          <span>Archivo</span>
        </button>

        <button
          onClick={() => onSelectTab('feed')}
          className={`relative flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-semibold transition-colors ${
            activeTab === 'feed' ? 'text-indigo-400' : 'text-cinema-textMuted'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>La Tertulia</span>
          {!currentUser && <Lock className="w-2.5 h-2.5 absolute top-1 right-2 text-cinema-gold" />}
        </button>

        <button
          onClick={() => onSelectTab('chats')}
          className={`relative flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-semibold transition-colors ${
            activeTab === 'chats' ? 'text-emerald-400' : 'text-cinema-textMuted'
          }`}
        >
          <MessageSquare className="w-4 h-4" />
          <span>Cineclubs</span>
          {!currentUser && <Lock className="w-2.5 h-2.5 absolute top-1 right-2 text-cinema-gold" />}
        </button>

        <button
          onClick={() => onSelectTab('profile')}
          className={`relative flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-semibold transition-colors ${
            activeTab === 'profile' ? 'text-amber-400' : 'text-cinema-textMuted'
          }`}
        >
          <UserIcon className="w-4 h-4" />
          <span>Filmoteca</span>
          {!currentUser && <Lock className="w-2.5 h-2.5 absolute top-1 right-2 text-cinema-gold" />}
        </button>
      </div>
    </>
  );
};

