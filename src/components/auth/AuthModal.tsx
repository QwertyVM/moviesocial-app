"use client";

import React, { useState } from 'react';
import { User, UserLocation } from '../../types';
import { AVAILABLE_CITIES } from '../../data/curatedMovies';
import { loginOrRegisterUser } from '@/actions/users';
import { api } from '../../services/api';
import {
  X,
  Film,
  Sparkles,
  User as UserIcon,
  AtSign,
  Mail,
  MapPin,
  Lock,
  ArrowRight,
  ShieldCheck,
  Check,
} from 'lucide-react';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (user: User) => void;
  initialMode?: 'login' | 'register';
  reason?: string;
  defaultLocation?: UserLocation;
}

export const AuthModal: React.FC<AuthModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
  initialMode = 'register',
  reason,
  defaultLocation = AVAILABLE_CITIES[0],
}) => {
  const [mode, setMode] = useState<'login' | 'register'>(initialMode);
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [selectedCity, setSelectedCity] = useState(defaultLocation.city);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    setMode(initialMode);
  }, [initialMode, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const userIdent = username.trim();
    if (!userIdent) {
      setError('Por favor ingresa un nombre de usuario.');
      return;
    }

    setLoading(true);
    try {
      const loc = AVAILABLE_CITIES.find((c) => c.city === selectedCity) || defaultLocation;
      const cleanUsername = userIdent.startsWith('@') ? userIdent : `@${userIdent}`;
      const name = displayName.trim() || cleanUsername.replace('@', '');
      const userEmail = email.trim() || `${cleanUsername.replace('@', '')}@cinefilo.com`;

      const user = await loginOrRegisterUser({
        displayName: name,
        username: cleanUsername,
        email: userEmail,
        city: loc.city,
        country: loc.country,
        countryCode: loc.countryCode,
      });

      api.login(user);
      onSuccess(user);
      onClose();
    } catch (err: any) {
      setError(err?.message || 'Error al autenticar. Intenta de nuevo.');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickSocialLogin = async (provider: 'apple' | 'google') => {
    setLoading(true);
    try {
      const seed = provider === 'apple' ? 'cinefilo_apple' : 'cinefilo_google';
      const user = await loginOrRegisterUser({
        displayName: provider === 'apple' ? 'Usuario Apple' : 'Usuario Google',
        username: `@${seed}_${Math.floor(100 + Math.random() * 900)}`,
        email: `${seed}@social.com`,
        city: defaultLocation.city,
        country: defaultLocation.country,
        countryCode: defaultLocation.countryCode,
      });

      api.login(user);
      onSuccess(user);
      onClose();
    } catch {
      setError('No se pudo completar el acceso social.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-fade-in">
      <div className="relative w-full max-w-md rounded-3xl bg-cinema-card border border-cinema-border p-6 sm:p-8 shadow-2xl flex flex-col gap-5 overflow-hidden">
        {/* Glow decoration */}
        <div className="absolute -top-12 -right-12 w-44 h-44 bg-cinema-gold/15 rounded-full blur-3xl pointer-events-none" />

        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 rounded-full bg-cinema-surface hover:bg-cinema-cardHover text-cinema-textMuted hover:text-white border border-cinema-border transition-colors z-10"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Header */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center gap-2">
            <span className="w-8 h-8 rounded-xl bg-cinema-gold/20 text-cinema-gold border border-cinema-gold/40 flex items-center justify-center">
              <Film className="w-4 h-4" />
            </span>
            <span className="text-xs font-bold text-cinema-gold uppercase tracking-wider">
              MovieSocial
            </span>
          </div>

          <h2 className="text-2xl font-extrabold text-white tracking-tight">
            {mode === 'register' ? 'Crea tu Cuenta Cinéfila' : 'Iniciar Sesión'}
          </h2>

          <p className="text-xs text-cinema-textSecondary leading-relaxed">
            {reason ||
              'El catálogo y la cartelera de estrenos son públicos. Inicia sesión para conectar con amigos, chatear en Cineclubs y calificar películas.'}
          </p>
        </div>

        {/* Mode Switcher Tabs */}
        <div className="flex items-center bg-cinema-surface p-1 rounded-2xl border border-cinema-border">
          <button
            type="button"
            onClick={() => {
              setMode('register');
              setError(null);
            }}
            className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
              mode === 'register'
                ? 'bg-cinema-card text-white shadow border border-cinema-border'
                : 'text-cinema-textSecondary hover:text-white'
            }`}
          >
            Crear Cuenta Real
          </button>
          <button
            type="button"
            onClick={() => {
              setMode('login');
              setError(null);
            }}
            className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
              mode === 'login'
                ? 'bg-cinema-card text-white shadow border border-cinema-border'
                : 'text-cinema-textSecondary hover:text-white'
            }`}
          >
            Ya tengo Cuenta
          </button>
        </div>

        {/* Error Alert */}
        {error && (
          <div className="p-3 rounded-xl bg-rose-950/70 border border-rose-500/40 text-rose-300 text-xs font-medium">
            {error}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="flex flex-col gap-3.5">
          {mode === 'register' && (
            <div className="flex flex-col gap-1">
              <label className="text-[11px] font-semibold text-cinema-textSecondary uppercase tracking-wider">
                Nombre y Apellido
              </label>
              <div className="relative">
                <UserIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-cinema-textMuted" />
                <input
                  type="text"
                  required
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="Ej. Víctor Manzanilla"
                  className="w-full pl-9 pr-3.5 py-2.5 rounded-xl bg-cinema-surface border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none"
                />
              </div>
            </div>
          )}

          {/* Username */}
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-semibold text-cinema-textSecondary uppercase tracking-wider">
              Nombre de Usuario
            </label>
            <div className="relative">
              <AtSign className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-cinema-textMuted" />
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Ej. @victor_cinefilo"
                className="w-full pl-9 pr-3.5 py-2.5 rounded-xl bg-cinema-surface border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none"
              />
            </div>
          </div>

          {/* Email */}
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-semibold text-cinema-textSecondary uppercase tracking-wider">
              Correo Electrónico
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-cinema-textMuted" />
              <input
                type="email"
                required={mode === 'register'}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="tu@correo.com"
                className="w-full pl-9 pr-3.5 py-2.5 rounded-xl bg-cinema-surface border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none"
              />
            </div>
          </div>

          {/* City Selector */}
          {mode === 'register' && (
            <div className="flex flex-col gap-1">
              <label className="text-[11px] font-semibold text-cinema-textSecondary uppercase tracking-wider">
                Tu Ciudad de Cartelera
              </label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-cinema-gold" />
                <select
                  value={selectedCity}
                  onChange={(e) => setSelectedCity(e.target.value)}
                  className="w-full pl-9 pr-3.5 py-2.5 rounded-xl bg-cinema-surface border border-cinema-border focus:border-cinema-gold text-xs text-white outline-none cursor-pointer"
                >
                  {AVAILABLE_CITIES.map((c) => (
                    <option key={c.city} value={c.city} className="bg-cinema-card text-white">
                      {c.flagEmoji} {c.city} ({c.country})
                    </option>
                  ))}
                </select>
              </div>
            </div>
          )}

          {/* Submit Button */}
          <button
            type="submit"
            disabled={loading}
            className="mt-2 w-full py-3 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black font-extrabold text-xs flex items-center justify-center gap-2 shadow-lg shadow-amber-900/40 transition-transform hover:scale-[1.02] disabled:opacity-50"
          >
            {loading ? (
              <span>Conectando...</span>
            ) : mode === 'register' ? (
              <>
                <span>Crear Cuenta e Ingresar</span>
                <ArrowRight className="w-4 h-4" />
              </>
            ) : (
              <>
                <span>Ingresar a MovieSocial</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Divider */}
        <div className="flex items-center gap-3 my-1">
          <div className="flex-grow h-px bg-cinema-border" />
          <span className="text-[10px] text-cinema-textMuted uppercase font-semibold">o continuar con</span>
          <div className="flex-grow h-px bg-cinema-border" />
        </div>

        {/* Social Quick Login */}
        <div className="grid grid-cols-2 gap-3">
          <button
            type="button"
            onClick={() => handleQuickSocialLogin('apple')}
            disabled={loading}
            className="py-2.5 rounded-xl bg-cinema-surface hover:bg-cinema-cardHover border border-cinema-border text-white text-xs font-semibold flex items-center justify-center gap-2 transition-colors"
          >
            <span> Apple</span>
          </button>
          <button
            type="button"
            onClick={() => handleQuickSocialLogin('google')}
            disabled={loading}
            className="py-2.5 rounded-xl bg-cinema-surface hover:bg-cinema-cardHover border border-cinema-border text-white text-xs font-semibold flex items-center justify-center gap-2 transition-colors"
          >
            <span>G Google</span>
          </button>
        </div>

        {/* Footer info */}
        <div className="flex items-center justify-center gap-1.5 text-[11px] text-cinema-textMuted pt-2">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
          <span>Datos guardados en Neon PostgreSQL Cloud</span>
        </div>
      </div>
    </div>
  );
};
