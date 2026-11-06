"use client";

import React, { useState } from 'react';
import { User, UserLocation } from '../../types';
import {
  Film,
  Users,
  MessageSquare,
  User as UserIcon,
  MapPin,
  ChevronDown,
  Check,
  Sparkles,
  Navigation,
  Lock,
  LogIn,
  LogOut,
  UserPlus,
  Globe,
} from 'lucide-react';
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
      {/* Top Header Navbar - Cinema Dark OLED Aesthetic */}
      <header className="sticky top-0 z-40 w-full border-b border-white/[0.08] bg-[#07080B]/85 backdrop-blur-2xl transition-colors">
        <div className="max-w-[1780px] mx-auto px-4 sm:px-8 lg:px-12 xl:px-16 h-16 flex items-center justify-between gap-4">
          
          {/* Logo & City Selector */}
          <div className="flex items-center gap-4 sm:gap-6">
            {/* Minimalist Cinephile Brand */}
            <button
              onClick={() => onSelectTab('catalog')}
              className="flex items-center gap-3 group focus:outline-none"
            >
              <div className="relative w-9 h-9 rounded-xl bg-gradient-to-b from-[#1E222B] to-[#0A0C10] border border-cinema-gold/30 flex items-center justify-center shadow-[0_0_16px_rgba(229,169,60,0.18)] group-hover:border-cinema-gold/60 group-hover:scale-105 transition-all">
                <Film className="w-4 h-4 text-cinema-gold transition-transform group-hover:rotate-12 duration-300" />
                <span className="absolute -bottom-1 -right-1 w-2 h-2 rounded-full bg-cinema-gold animate-ping opacity-75" />
                <span className="absolute -bottom-1 -right-1 w-2 h-2 rounded-full bg-cinema-gold" />
              </div>
              <div className="flex flex-col text-left">
                <span className="font-black text-sm tracking-[0.18em] text-white group-hover:text-cinema-gold transition-colors">
                  MOVIESOCIAL
                </span>
                <span className="text-[9px] font-mono tracking-widest text-cinema-textMuted uppercase hidden sm:inline">
                  Filmoteca & Salas
                </span>
              </div>
            </button>

            {/* Location Selector Pill */}
            <div className="relative">
              <button
                onClick={() => setCityDropdownOpen(!cityDropdownOpen)}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/[0.04] hover:bg-white/[0.08] border border-white/[0.08] hover:border-cinema-gold/40 transition-all text-xs font-medium text-gray-200"
                title="Cambiar tu ciudad para consultar salas y horarios"
                suppressHydrationWarning
              >
                <MapPin className="w-3.5 h-3.5 text-cinema-gold" />
                <span className="mr-0.5" suppressHydrationWarning>{activeLocation.flagEmoji}</span>
                <span className="font-mono text-[11px]" suppressHydrationWarning>{activeLocation.city}</span>
                <ChevronDown className="w-3 h-3 text-cinema-textMuted" />
              </button>

              {cityDropdownOpen && (
                <div className="absolute left-0 mt-2 w-64 rounded-2xl bg-[#0D0F14] border border-white/10 shadow-2xl z-50 p-2 max-h-80 overflow-y-auto backdrop-blur-2xl">
                  {/* Botón GPS */}
                  <button
                    onClick={handleDetectGPS}
                    disabled={gpsLoading}
                    className="w-full mb-2 flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-cinema-gold/15 hover:bg-cinema-gold/25 border border-cinema-gold/30 text-cinema-gold font-semibold text-xs transition-colors"
                  >
                    <Navigation className={`w-3.5 h-3.5 ${gpsLoading ? 'animate-spin' : ''}`} />
                    <span>{gpsLoading ? 'Detectando GPS...' : 'Detectar mi ubicación'}</span>
                  </button>

                  <div className="px-2 py-1 text-[10px] font-mono text-cinema-textMuted uppercase tracking-wider">
                    Ciudades Disponibles:
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
                        className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs text-left transition-colors ${
                          isSelected
                            ? 'bg-cinema-gold/15 text-cinema-gold font-bold'
                            : 'text-gray-300 hover:bg-white/5'
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

          {/* Center Navigation Tabs (Desktop) - Clean Floating Pill */}
          <div className="hidden lg:flex items-center">
            <nav className="flex items-center gap-1 bg-[#0D0F14]/90 p-1 rounded-full border border-white/[0.08] shadow-2xl backdrop-blur-xl">
              {/* Estrenos */}
              <button
                onClick={() => onSelectTab('catalog')}
                className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs transition-all ${
                  activeTab === 'catalog'
                    ? 'bg-amber-500/15 text-cinema-gold font-bold border border-cinema-gold/40 shadow-[0_0_12px_rgba(229,169,60,0.15)]'
                    : 'text-gray-400 hover:text-white hover:bg-white/[0.04] font-medium'
                }`}
              >
                <Film className="w-3.5 h-3.5" />
                <span>Estrenos</span>
              </button>

              {/* Filmoteca Mundial */}
              <button
                onClick={() => onSelectTab('archive')}
                className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs transition-all ${
                  activeTab === 'archive'
                    ? 'bg-amber-500/15 text-cinema-gold font-bold border border-cinema-gold/40 shadow-[0_0_12px_rgba(229,169,60,0.15)]'
                    : 'text-gray-400 hover:text-white hover:bg-white/[0.04] font-medium'
                }`}
              >
                <Globe className="w-3.5 h-3.5" />
                <span>Filmoteca Mundial</span>
              </button>

              {/* La Tertulia */}
              <button
                onClick={() => onSelectTab('feed')}
                className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs transition-all ${
                  activeTab === 'feed'
                    ? 'bg-amber-500/15 text-cinema-gold font-bold border border-cinema-gold/40 shadow-[0_0_12px_rgba(229,169,60,0.15)]'
                    : 'text-gray-400 hover:text-white hover:bg-white/[0.04] font-medium'
                }`}
              >
                <Users className="w-3.5 h-3.5" />
                <span>La Tertulia</span>
                {!currentUser && <Lock className="w-3 h-3 text-cinema-textMuted/70" />}
              </button>

              {/* Cineclubs */}
              <button
                onClick={() => onSelectTab('chats')}
                className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs transition-all ${
                  activeTab === 'chats'
                    ? 'bg-amber-500/15 text-cinema-gold font-bold border border-cinema-gold/40 shadow-[0_0_12px_rgba(229,169,60,0.15)]'
                    : 'text-gray-400 hover:text-white hover:bg-white/[0.04] font-medium'
                }`}
              >
                <MessageSquare className="w-3.5 h-3.5" />
                <span>Cineclubs</span>
                {!currentUser && <Lock className="w-3 h-3 text-cinema-textMuted/70" />}
              </button>

              {/* Mi Perfil */}
              <button
                onClick={() => onSelectTab('profile')}
                className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs transition-all ${
                  activeTab === 'profile'
                    ? 'bg-amber-500/15 text-cinema-gold font-bold border border-cinema-gold/40 shadow-[0_0_12px_rgba(229,169,60,0.15)]'
                    : 'text-gray-400 hover:text-white hover:bg-white/[0.04] font-medium'
                }`}
              >
                <UserIcon className="w-3.5 h-3.5" />
                <span>Mi Perfil</span>
                {!currentUser && <Lock className="w-3 h-3 text-cinema-textMuted/70" />}
              </button>
            </nav>
          </div>

          {/* Right Side: Auth / User Profile */}
          <div className="flex items-center gap-2.5">
            {currentUser ? (
              <>
                {/* Subscription status pill */}
                <button
                  onClick={() => onOpenSubscriptionModal?.()}
                  className={`hidden sm:flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold transition-all ${
                    currentUser.isPremium
                      ? 'bg-amber-500/15 hover:bg-amber-500/25 text-cinema-gold border border-cinema-gold/40 shadow-sm'
                      : 'bg-white/[0.04] hover:bg-white/[0.08] text-gray-300 border border-white/[0.08]'
                  }`}
                  title={
                    currentUser.isPremium
                      ? 'Membresía Cinéfilo Pro activa'
                      : 'Plan Base: Clic para activar suscripción global'
                  }
                >
                  <Sparkles className="w-3 h-3 text-cinema-gold fill-cinema-gold" />
                  <span>{currentUser.isPremium ? 'Cinéfilo Pro' : 'Plan Base'}</span>
                </button>

                {/* User Profile Pill */}
                <button
                  onClick={() => onSelectTab('profile')}
                  className="flex items-center gap-2 p-1 sm:pr-3 rounded-full bg-white/[0.04] hover:bg-white/[0.08] border border-white/[0.08] hover:border-cinema-gold/40 transition-all group"
                >
                  <img
                    src={currentUser.avatarUrl}
                    alt={currentUser.displayName}
                    className="w-7 h-7 rounded-full object-cover border border-cinema-gold/40"
                  />
                  <span className="hidden sm:inline text-xs font-semibold text-gray-200 group-hover:text-cinema-gold transition-colors">
                    {currentUser.displayName}
                  </span>
                </button>

                {/* Logout Button */}
                {onLogout && (
                  <button
                    onClick={onLogout}
                    className="p-1.5 rounded-full bg-white/[0.04] hover:bg-red-500/15 text-gray-400 hover:text-red-400 border border-white/[0.08] hover:border-red-500/30 transition-colors"
                    title="Cerrar Sesión"
                  >
                    <LogOut className="w-3.5 h-3.5" />
                  </button>
                )}
              </>
            ) : (
              <div className="flex items-center gap-2">
                <button
                  onClick={() => onOpenAuthModal?.('login')}
                  className="px-3.5 py-1.5 rounded-full text-xs font-medium text-gray-300 hover:text-white hover:bg-white/[0.05] transition-colors"
                >
                  <span>Ingresar</span>
                </button>

                <button
                  onClick={() => onOpenAuthModal?.('register')}
                  className="flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold shadow-[0_0_15px_rgba(229,169,60,0.25)] transition-transform hover:scale-105"
                >
                  <UserPlus className="w-3.5 h-3.5" />
                  <span>Crear Cuenta</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Mobile Bottom Navigation Bar - Minimal Cinema Dark */}
      <div className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-[#07080B]/95 border-t border-white/[0.08] backdrop-blur-2xl px-2 py-2 flex items-center justify-around">
        <button
          onClick={() => onSelectTab('catalog')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl text-[10px] font-semibold transition-colors ${
            activeTab === 'catalog' ? 'text-cinema-gold' : 'text-gray-400'
          }`}
        >
          <Film className="w-4 h-4" />
          <span>Cartelera</span>
        </button>

        <button
          onClick={() => onSelectTab('archive')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl text-[10px] font-semibold transition-colors ${
            activeTab === 'archive' ? 'text-cinema-gold' : 'text-gray-400'
          }`}
        >
          <Globe className="w-4 h-4" />
          <span>Filmoteca</span>
        </button>

        <button
          onClick={() => onSelectTab('feed')}
          className={`relative flex flex-col items-center gap-1 py-1 px-3 rounded-xl text-[10px] font-semibold transition-colors ${
            activeTab === 'feed' ? 'text-cinema-gold' : 'text-gray-400'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>La Tertulia</span>
          {!currentUser && <Lock className="w-2.5 h-2.5 absolute top-1 right-2 text-cinema-gold" />}
        </button>

        <button
          onClick={() => onSelectTab('chats')}
          className={`relative flex flex-col items-center gap-1 py-1 px-3 rounded-xl text-[10px] font-semibold transition-colors ${
            activeTab === 'chats' ? 'text-cinema-gold' : 'text-gray-400'
          }`}
        >
          <MessageSquare className="w-4 h-4" />
          <span>Cineclubs</span>
          {!currentUser && <Lock className="w-2.5 h-2.5 absolute top-1 right-2 text-cinema-gold" />}
        </button>

        <button
          onClick={() => onSelectTab('profile')}
          className={`relative flex flex-col items-center gap-1 py-1 px-3 rounded-xl text-[10px] font-semibold transition-colors ${
            activeTab === 'profile' ? 'text-cinema-gold' : 'text-gray-400'
          }`}
        >
          <UserIcon className="w-4 h-4" />
          <span>Perfil</span>
          {!currentUser && <Lock className="w-2.5 h-2.5 absolute top-1 right-2 text-cinema-gold" />}
        </button>
      </div>
    </>
  );
};
