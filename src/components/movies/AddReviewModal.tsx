"use client";

import React, { useState } from 'react';
import { Movie, Review, User } from '../../types';
import { StarRatingPicker } from '../common/StarRatingPicker';
import { X, Send, Globe, Users, Lock, Sparkles } from 'lucide-react';

interface AddReviewModalProps {
  movie: Movie;
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: {
    movieId: string;
    movieTitle: string;
    moviePosterUrl?: string;
    movieReleaseYear?: number;
    rating: number;
    comment: string;
    isCommunity: boolean;
  }) => Promise<Review>;
  currentUser?: User;
  onOpenSubscriptionModal?: (reason?: string) => void;
}

export const AddReviewModal: React.FC<AddReviewModalProps> = ({
  movie,
  isOpen,
  onClose,
  onSubmit,
  currentUser,
  onOpenSubscriptionModal,
}) => {
  const [rating, setRating] = useState<number>(4.5);
  const [comment, setComment] = useState<string>('');
  const isSubscribed = Boolean(currentUser?.isPremium);
  // Si no tiene suscripción mensual, su reseña es estrictamente para amigos (Plan Base)
  const [isCommunity, setIsCommunity] = useState<boolean>(isSubscribed);
  const [submitting, setSubmitting] = useState<boolean>(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!comment.trim()) return;
    setSubmitting(true);
    try {
      await onSubmit({
        movieId: movie.id,
        movieTitle: movie.title,
        moviePosterUrl: movie.posterURL,
        movieReleaseYear: movie.releaseYear,
        rating,
        comment: comment.trim(),
        // Forzar false si está en Plan Base
        isCommunity: isSubscribed ? isCommunity : false,
      });
      onClose();
    } catch (err) {
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleCommunity = (targetCommunity: boolean) => {
    if (targetCommunity && !isSubscribed) {
      if (onOpenSubscriptionModal) {
        onOpenSubscriptionModal(
          'Para que tus comentarios se puedan ver al mundo e interactuar con la comunidad, necesitas la suscripción mensual de perfil. En el Plan Base actual, tus comentarios son exclusivos para tus amigos.'
        );
      }
      return;
    }
    setIsCommunity(targetCommunity);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div className="relative w-full max-w-lg rounded-2xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-5">
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-cinema-border">
          <div className="flex items-center gap-3">
            <img
              src={movie.posterURL}
              alt={movie.title}
              className="w-10 h-14 rounded-lg object-cover border border-cinema-border"
            />
            <div>
              <h3 className="font-bold text-base text-white line-clamp-1">{movie.title}</h3>
              <p className="text-xs text-cinema-textMuted">Tu micro-reseña y calificación</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-cinema-textMuted hover:text-white hover:bg-cinema-surface transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="flex flex-col gap-5">
          {/* Rating Picker */}
          <div className="flex flex-col gap-2">
            <label className="text-xs font-semibold text-cinema-textSecondary uppercase tracking-wider">
              Calificación (1 a 5 estrellas con medios puntos)
            </label>
            <div className="p-3.5 rounded-xl bg-cinema-surface border border-cinema-border flex items-center justify-between">
              <StarRatingPicker value={rating} onChange={setRating} size="lg" />
            </div>
          </div>

          {/* Comment Textarea */}
          <div className="flex flex-col gap-2">
            <label className="text-xs font-semibold text-cinema-textSecondary uppercase tracking-wider">
              Tu Opinión Cinéfila
            </label>
            <textarea
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              placeholder="¿Qué te pareció la dirección, fotografía, actuaciones o guion? Comparte sin spoilers..."
              rows={4}
              required
              className="w-full px-3.5 py-2.5 rounded-xl bg-cinema-surface border border-cinema-border focus:border-cinema-gold focus:ring-1 focus:ring-cinema-gold text-sm text-white placeholder-cinema-textMuted resize-none outline-none transition-colors"
            />
          </div>

          {/* Scope Selector: Friends vs Community with Plan Logic */}
          <div className="flex flex-col gap-2 p-3.5 rounded-2xl bg-cinema-surface border border-cinema-border">
            <span className="text-[11px] font-semibold text-cinema-textSecondary uppercase tracking-wider">
              ¿Quién puede ver tu comentario?
            </span>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {/* Option 1: Solo Amigos (Base Plan) */}
              <button
                type="button"
                onClick={() => handleToggleCommunity(false)}
                className={`p-3 rounded-xl border flex items-start gap-2.5 text-left transition-all ${
                  !isCommunity
                    ? 'bg-purple-950/50 border-purple-500/50 text-white shadow-sm'
                    : 'bg-cinema-card/50 border-cinema-border/50 text-cinema-textSecondary hover:border-cinema-border'
                }`}
              >
                <div className={`p-1.5 rounded-lg flex-shrink-0 mt-0.5 ${!isCommunity ? 'bg-purple-900/60 text-purple-300' : 'bg-cinema-surface text-cinema-textMuted'}`}>
                  <Users className="w-3.5 h-3.5" />
                </div>
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-white flex items-center gap-1.5">
                    Solo mis Amigos
                    <span className="text-[9px] font-normal px-1.5 py-0.2 rounded bg-zinc-800 text-zinc-400">Base</span>
                  </span>
                  <span className="text-[10px] text-cinema-textMuted leading-tight mt-0.5">
                    Visible en el feed de tus amigos mutuos.
                  </span>
                </div>
              </button>

              {/* Option 2: Comunidad Global (Monthly Subscription required) */}
              <button
                type="button"
                onClick={() => handleToggleCommunity(true)}
                className={`p-3 rounded-xl border flex items-start gap-2.5 text-left transition-all relative ${
                  isCommunity
                    ? 'bg-amber-950/40 border-cinema-gold text-white shadow-sm'
                    : 'bg-cinema-card/50 border-cinema-border/50 text-cinema-textSecondary hover:border-cinema-border'
                }`}
              >
                {!isSubscribed && (
                  <span className="absolute -top-2 right-2 px-1.5 py-0.2 rounded-full bg-cinema-gold text-black text-[9px] font-extrabold uppercase tracking-wider flex items-center gap-1">
                    <Lock className="w-2.5 h-2.5" /> Suscripción
                  </span>
                )}
                <div className={`p-1.5 rounded-lg flex-shrink-0 mt-0.5 ${isCommunity ? 'bg-amber-900/60 text-cinema-gold' : 'bg-cinema-surface text-cinema-textMuted'}`}>
                  <Globe className="w-3.5 h-3.5" />
                </div>
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-white flex items-center gap-1.5">
                    Comunidad Global
                    {isSubscribed && (
                      <span className="text-[9px] font-bold px-1.5 py-0.2 rounded bg-cinema-gold/20 text-cinema-gold border border-cinema-gold/30">Pro</span>
                    )}
                  </span>
                  <span className="text-[10px] text-cinema-textMuted leading-tight mt-0.5">
                    {isSubscribed
                      ? 'Visible al mundo entero en la ficha de la película.'
                      : 'Requiere suscripción mensual para verse al mundo.'}
                  </span>
                </div>
              </button>
            </div>
          </div>

          {/* Buttons */}
          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-xl text-xs font-semibold text-cinema-textSecondary hover:text-white hover:bg-cinema-surface transition-colors"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={submitting || !comment.trim()}
              className="px-5 py-2.5 rounded-xl bg-cinema-gold hover:bg-amber-400 disabled:opacity-50 text-black font-bold text-xs flex items-center gap-2 shadow-lg shadow-amber-900/30 transition-all hover:scale-105"
            >
              <Send className="w-3.5 h-3.5" />
              <span>{submitting ? 'Publicando...' : 'Publicar Reseña'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

