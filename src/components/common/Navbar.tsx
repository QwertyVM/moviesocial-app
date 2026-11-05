"use client";

import React, { useState } from 'react';
import { User, UserLocation } from '../../types';
import { Film, Users, MessageSquare, User as UserIcon, MapPin, ChevronDown, Check, Sparkles, Database } from 'lucide-react';
import { AVAILABLE_CITIES } from '../../data/curatedMovies';

interface NavbarProps {
  activeTab: 'catalog' | 'feed' | 'chats' | 'profile';
  onSelectTab: (tab: 'catalog' | 'feed' | 'chats' | 'profile') => void;
  currentUser: User;
  onSelectCity: (city: UserLocation) => void;
  dbStatus?: { online: boolean; database?: string };
}

export const Navbar: React.FC<NavbarProps> = ({
  activeTab,
  onSelectTab,
  currentUser,
  onSelectCity,
  dbStatus,
}) => {
  const [cityDropdownOpen, setCityDropdownOpen] = useState(false);

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
              >
                <MapPin className="w-3.5 h-3.5 text-cinema-gold" />
                <span className="mr-0.5">{currentUser.location.flagEmoji}</span>
                <span>{currentUser.location.city}</span>
                <ChevronDown className="w-3.5 h-3.5 text-cinema-textMuted" />
              </button>

              {cityDropdownOpen && (
                <div className="absolute left-0 mt-2 w-64 rounded-xl bg-cinema-card border border-cinema-border shadow-2xl z-50 py-2 max-h-80 overflow-y-auto">
                  <div className="px-3 py-1.5 text-[11px] font-semibold text-cinema-textMuted uppercase tracking-wider">
                    Selecciona tu Ciudad (Cartelera)
                  </div>
                  {AVAILABLE_CITIES.map((loc) => {
                    const isSelected = loc.city === currentUser.location.city;
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
          <nav className="hidden md:flex items-center gap-1 bg-cinema-surface p-1 rounded-xl border border-cinema-border">
            <button
              onClick={() => onSelectTab('catalog')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                activeTab === 'catalog'
                  ? 'bg-cinema-card text-white shadow border border-cinema-border'
                  : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
              }`}
            >
              <Film className="w-4 h-4 text-cinema-gold" />
              <span>Cine & Cartelera</span>
            </button>

            <button
              onClick={() => onSelectTab('feed')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                activeTab === 'feed'
                  ? 'bg-cinema-card text-white shadow border border-cinema-border'
                  : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
              }`}
            >
              <Users className="w-4 h-4 text-indigo-400" />
              <span>Amigos</span>
            </button>

            <button
              onClick={() => onSelectTab('chats')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                activeTab === 'chats'
                  ? 'bg-cinema-card text-white shadow border border-cinema-border'
                  : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
              }`}
            >
              <MessageSquare className="w-4 h-4 text-emerald-400" />
              <span>Chats & Cineclubs</span>
            </button>

            <button
              onClick={() => onSelectTab('profile')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                activeTab === 'profile'
                  ? 'bg-cinema-card text-white shadow border border-cinema-border'
                  : 'text-cinema-textSecondary hover:text-white hover:bg-cinema-card/50'
              }`}
            >
              <UserIcon className="w-4 h-4 text-amber-400" />
              <span>Mi Perfil</span>
            </button>
          </nav>

          {/* Right Side: DB indicator & User Pill */}
          <div className="flex items-center gap-3">
            {/* Database indicator */}
            <div
              className="hidden lg:flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-cinema-surface border border-cinema-border text-[11px] text-cinema-textSecondary"
              title={dbStatus?.online ? `Base de Datos: ${dbStatus.database}` : 'Modo Offline con caché reactivo'}
            >
              <span className={`w-2 h-2 rounded-full ${dbStatus?.online ? 'bg-emerald-500 animate-pulse' : 'bg-cinema-gold'}`} />
              <Database className="w-3 h-3 text-cinema-textMuted" />
              <span>{dbStatus?.online ? 'REST API Online' : 'Caché Activo'}</span>
            </div>

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
          </div>
        </div>
      </header>

      {/* Mobile Bottom Navigation Bar */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-cinema-bg/95 border-t border-cinema-border backdrop-blur-lg px-2 py-2 flex items-center justify-around">
        <button
          onClick={() => onSelectTab('catalog')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-medium transition-colors ${
            activeTab === 'catalog' ? 'text-cinema-gold' : 'text-cinema-textMuted'
          }`}
        >
          <Film className="w-5 h-5" />
          <span>Cine</span>
        </button>

        <button
          onClick={() => onSelectTab('feed')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-medium transition-colors ${
            activeTab === 'feed' ? 'text-indigo-400' : 'text-cinema-textMuted'
          }`}
        >
          <Users className="w-5 h-5" />
          <span>Amigos</span>
        </button>

        <button
          onClick={() => onSelectTab('chats')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-medium transition-colors ${
            activeTab === 'chats' ? 'text-emerald-400' : 'text-cinema-textMuted'
          }`}
        >
          <MessageSquare className="w-5 h-5" />
          <span>Chats</span>
        </button>

        <button
          onClick={() => onSelectTab('profile')}
          className={`flex flex-col items-center gap-1 py-1 px-3 rounded-lg text-[10px] font-medium transition-colors ${
            activeTab === 'profile' ? 'text-amber-400' : 'text-cinema-textMuted'
          }`}
        >
          <UserIcon className="w-5 h-5" />
          <span>Perfil</span>
        </button>
      </div>
    </>
  );
};

