"use client";

import React, { useState } from 'react';
import { User } from '../../types';
import {
  X,
  Sparkles,
  Globe,
  Users,
  Check,
  ShieldCheck,
  Lock,
  ArrowRight,
  MessageCircle,
  Film,
} from 'lucide-react';

interface SubscriptionModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentUser: User;
  onSubscribe: () => void;
  onCancelSubscription?: () => void;
  triggerReason?: string;
}

export const SubscriptionModal: React.FC<SubscriptionModalProps> = ({
  isOpen,
  onClose,
  currentUser,
  onSubscribe,
  onCancelSubscription,
  triggerReason,
}) => {
  const [processing, setProcessing] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  if (!isOpen) return null;

  const isSubscribed = currentUser.isPremium;

  const handleAction = async () => {
    setProcessing(true);
    try {
      if (isSubscribed) {
        if (onCancelSubscription) onCancelSubscription();
        setSuccessMessage('Has vuelto al Plan Base (solo amigos).');
      } else {
        onSubscribe();
        setSuccessMessage('¡Suscripción mensual activada! Ahora tus comentarios e interacciones son visibles al mundo.');
      }
      setTimeout(() => {
        setSuccessMessage(null);
        setProcessing(false);
        onClose();
      }, 1400);
    } catch {
      setProcessing(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-fade-in">
      <div className="relative w-full max-w-2xl rounded-3xl bg-cinema-card border border-cinema-border p-6 sm:p-8 shadow-2xl flex flex-col gap-6 overflow-hidden">
        {/* Glow decorative effect */}
        <div className="absolute -top-16 -right-16 w-56 h-56 bg-cinema-gold/15 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-16 -left-16 w-56 h-56 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />

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
            <span className="px-3 py-1 rounded-full bg-cinema-gold/20 text-cinema-gold text-xs font-bold border border-cinema-gold/40 flex items-center gap-1.5 uppercase tracking-wider">
              <Sparkles className="w-3.5 h-3.5" />
              Suscripción por Perfil
            </span>
            {isSubscribed ? (
              <span className="px-2.5 py-0.5 rounded-full bg-emerald-950/70 text-emerald-300 border border-emerald-500/30 text-xs font-semibold">
                ● Plan Mensual Activo
              </span>
            ) : (
              <span className="px-2.5 py-0.5 rounded-full bg-zinc-800 text-zinc-300 border border-zinc-700 text-xs font-semibold">
                ● Plan Base (Solo Amigos)
              </span>
            )}
          </div>

          <h2 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
            Interactúa con el Mundo Cinéfilo
          </h2>

          <p className="text-xs sm:text-sm text-cinema-textSecondary max-w-xl">
            {triggerReason ||
              'En el Plan Base tus comentarios e interacciones son exclusivos para tu círculo de amigos. Con la suscripción mensual, tus críticas son públicas para el mundo entero e interactúas con toda la comunidad.'}
          </p>
        </div>

        {/* Success Alert if toggled */}
        {successMessage && (
          <div className="p-3.5 rounded-2xl bg-emerald-950/80 border border-emerald-500/40 text-emerald-200 text-xs font-semibold flex items-center gap-2 animate-fade-in">
            <Check className="w-4 h-4 text-emerald-400 flex-shrink-0" />
            <span>{successMessage}</span>
          </div>
        )}

        {/* Plans Comparison Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Plan Base */}
          <div
            className={`p-5 rounded-2xl border flex flex-col justify-between gap-4 transition-all ${
              !isSubscribed
                ? 'bg-cinema-surface/90 border-cinema-border shadow-md'
                : 'bg-cinema-surface/40 border-cinema-border/50 opacity-70'
            }`}
          >
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-purple-950/60 border border-purple-500/30 flex items-center justify-center text-purple-400">
                    <Users className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="font-bold text-sm text-white">Plan Base</h3>
                    <span className="text-[10px] text-cinema-textMuted">Círculo Cercano</span>
                  </div>
                </div>
                <span className="text-sm font-bold text-gray-300 font-mono">Gratis</span>
              </div>

              <ul className="flex flex-col gap-2.5 text-xs text-gray-300 pt-2 border-t border-cinema-border/60">
                <li className="flex items-start gap-2">
                  <Check className="w-4 h-4 text-purple-400 flex-shrink-0 mt-0.5" />
                  <span>Interactuar y chatear 1 a 1 con tus <strong>amigos mutuos</strong>.</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-4 h-4 text-purple-400 flex-shrink-0 mt-0.5" />
                  <span>Reseñas y notas visibles <strong>únicamente para tus amigos</strong>.</span>
                </li>
                <li className="flex items-start gap-2 text-cinema-textMuted">
                  <Lock className="w-4 h-4 text-amber-500/70 flex-shrink-0 mt-0.5" />
                  <span>Sin visibilidad en las fichas del mundo ni feed global.</span>
                </li>
                <li className="flex items-start gap-2 text-cinema-textMuted">
                  <Lock className="w-4 h-4 text-amber-500/70 flex-shrink-0 mt-0.5" />
                  <span>Sin participación en Cineclubs abiertos comunitarios.</span>
                </li>
              </ul>
            </div>

            {!isSubscribed && (
              <span className="text-[11px] font-semibold text-center text-cinema-textMuted py-1 rounded-xl bg-cinema-card border border-cinema-border">
                Tu plan actual
              </span>
            )}
          </div>

          {/* Suscripción Mensual (Comunidad Global) */}
          <div
            className={`p-5 rounded-2xl border relative flex flex-col justify-between gap-4 transition-all ${
              isSubscribed
                ? 'bg-gradient-to-b from-amber-950/30 to-cinema-card border-cinema-gold/60 shadow-xl'
                : 'bg-gradient-to-b from-amber-950/20 to-cinema-card border-cinema-gold/30 hover:border-cinema-gold/60'
            }`}
          >
            {/* Best Value Tag */}
            <div className="absolute -top-3 right-4 px-2.5 py-0.5 rounded-full bg-cinema-gold text-black text-[10px] font-extrabold uppercase tracking-wider shadow">
              Recomendado
            </div>

            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-amber-950/60 border border-cinema-gold/40 flex items-center justify-center text-cinema-gold">
                    <Globe className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="font-bold text-sm text-white">Comunidad Global</h3>
                    <span className="text-[10px] text-cinema-gold font-medium">Suscripción Mensual</span>
                  </div>
                </div>
                <div className="flex flex-col items-end">
                  <span className="text-sm font-extrabold text-cinema-gold font-mono">S/ 14.90</span>
                  <span className="text-[10px] text-cinema-textMuted">al mes</span>
                </div>
              </div>

              <ul className="flex flex-col gap-2.5 text-xs text-white pt-2 border-t border-cinema-border/60">
                <li className="flex items-start gap-2">
                  <Check className="w-4 h-4 text-cinema-gold flex-shrink-0 mt-0.5" />
                  <span><strong>Comentarios visibles al mundo:</strong> Publica en la ficha global de cada película.</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-4 h-4 text-cinema-gold flex-shrink-0 mt-0.5" />
                  <span><strong>Interactuar con la comunidad:</strong> Debates y respuestas en el feed social público.</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-4 h-4 text-cinema-gold flex-shrink-0 mt-0.5" />
                  <span><strong>Cineclubs Abiertos:</strong> Únete y opina en las salas de cinéfilos del mundo.</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="w-4 h-4 text-cinema-gold flex-shrink-0 mt-0.5" />
                  <span><strong>Insignia Cinéfilo Pro:</strong> Distintivo dorado ✨ en tu perfil y comentarios.</span>
                </li>
              </ul>
            </div>

            {isSubscribed ? (
              <span className="text-[11px] font-bold text-center text-cinema-gold py-1 rounded-xl bg-cinema-gold/15 border border-cinema-gold/30">
                ✓ Tu suscripción mensual está activa
              </span>
            ) : (
              <span className="text-[10px] text-center text-cinema-textMuted">
                Facturación mensual • Cancela cuando quieras
              </span>
            )}
          </div>
        </div>

        {/* Footer Actions */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-3 border-t border-cinema-border">
          <div className="flex items-center gap-2 text-xs text-cinema-textMuted">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>Paga con seguridad • Acceso instantáneo en tu perfil</span>
          </div>

          <div className="flex items-center gap-3 w-full sm:w-auto">
            <button
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl text-xs font-semibold text-cinema-textSecondary hover:text-white hover:bg-cinema-surface transition-colors flex-1 sm:flex-none"
            >
              Cerrar
            </button>

            <button
              onClick={handleAction}
              disabled={processing}
              className={`px-5 py-2.5 rounded-xl font-bold text-xs flex items-center justify-center gap-2 transition-all shadow-lg flex-1 sm:flex-none ${
                isSubscribed
                  ? 'bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-600'
                  : 'bg-cinema-gold hover:bg-amber-400 text-black shadow-amber-900/40 hover:scale-105'
              }`}
            >
              {processing ? (
                <span>Procesando...</span>
              ) : isSubscribed ? (
                <span>Pausar y Volver al Plan Base</span>
              ) : (
                <>
                  <span>Suscribirme por S/ 14.90 / mes</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
