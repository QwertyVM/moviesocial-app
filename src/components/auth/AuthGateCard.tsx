"use client";

import React from 'react';
import { Lock, Sparkles, Film, ArrowRight } from 'lucide-react';

interface AuthGateCardProps {
  title: string;
  subtitle: string;
  icon: React.ReactNode;
  onOpenAuth: () => void;
  onGoToCatalog: () => void;
}

export const AuthGateCard: React.FC<AuthGateCardProps> = ({
  title,
  subtitle,
  icon,
  onOpenAuth,
  onGoToCatalog,
}) => {
  return (
    <div className="max-w-2xl mx-auto px-4 py-16 flex flex-col items-center text-center animate-fade-in">
      <div className="relative p-8 sm:p-12 rounded-3xl bg-cinema-card border border-cinema-border shadow-2xl flex flex-col items-center gap-6 overflow-hidden w-full">
        {/* Glow behind icon */}
        <div className="absolute top-0 w-56 h-56 bg-cinema-gold/10 rounded-full blur-3xl pointer-events-none" />

        <div className="relative">
          <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-3xl bg-cinema-surface border border-cinema-gold/40 flex items-center justify-center text-cinema-gold shadow-xl">
            {icon}
          </div>
          <div className="absolute -bottom-1 -right-1 p-1.5 rounded-full bg-cinema-gold text-black shadow-lg">
            <Lock className="w-4 h-4" />
          </div>
        </div>

        <div className="flex flex-col gap-2 max-w-lg">
          <span className="px-3 py-1 rounded-full bg-cinema-gold/15 text-cinema-gold border border-cinema-gold/30 text-xs font-bold uppercase tracking-wider inline-flex items-center justify-center gap-1.5 self-center">
            <Sparkles className="w-3.5 h-3.5" />
            Acceso Requiere Inicio de Sesión
          </span>

          <h2 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight mt-1">
            {title}
          </h2>

          <p className="text-xs sm:text-sm text-cinema-textSecondary leading-relaxed">
            {subtitle}
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-center gap-3 w-full sm:w-auto pt-2">
          <button
            onClick={onOpenAuth}
            className="w-full sm:w-auto px-6 py-3 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black font-extrabold text-xs flex items-center justify-center gap-2 shadow-lg shadow-amber-900/40 transition-transform hover:scale-105"
          >
            <span>Iniciar Sesión / Crear Cuenta</span>
            <ArrowRight className="w-4 h-4" />
          </button>

          <button
            onClick={onGoToCatalog}
            className="w-full sm:w-auto px-5 py-3 rounded-xl bg-cinema-surface hover:bg-cinema-cardHover border border-cinema-border text-cinema-textSecondary hover:text-white font-semibold text-xs flex items-center justify-center gap-2 transition-colors"
          >
            <Film className="w-4 h-4 text-cinema-gold" />
            <span>Ver Películas en Cartelera</span>
          </button>
        </div>

        <div className="pt-4 border-t border-cinema-border/60 text-[11px] text-cinema-textMuted flex items-center gap-2">
          <span>✓ La cartelera y el catálogo son 100% públicos para todo el mundo</span>
        </div>
      </div>
    </div>
  );
};

