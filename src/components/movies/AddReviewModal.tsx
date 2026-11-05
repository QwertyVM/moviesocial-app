"use client";

import React, { useState } from 'react';
import { Movie, Review } from '../../types';
import { StarRatingPicker } from '../common/StarRatingPicker';
import { X, Send, Globe, Users } from 'lucide-react';

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
}

export const AddReviewModal: React.FC<AddReviewModalProps> = ({
  movie,
  isOpen,
  onClose,
  onSubmit,
}) => {
  const [rating, setRating] = useState<number>(4.5);
  const [comment, setComment] = useState<string>('');
  const [isCommunity, setIsCommunity] = useState<boolean>(true);
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
        isCommunity,
      });
      onClose();
    } catch (err) {
      console.error(err);
    } finally {
      setSubmitting(false);
    }
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

          {/* Scope Selector: Friends vs Community */}
          <div className="flex items-center justify-between p-3 rounded-xl bg-cinema-surface border border-cinema-border">
            <div className="flex items-center gap-2.5">
              {isCommunity ? (
                <Globe className="w-4 h-4 text-emerald-400" />
              ) : (
                <Users className="w-4 h-4 text-purple-400" />
              )}
              <div className="flex flex-col">
                <span className="text-xs font-semibold text-white">
                  {isCommunity ? 'Público en la Comunidad' : 'Solo mis Amigos'}
                </span>
                <span className="text-[10px] text-cinema-textMuted">
                  {isCommunity
                    ? 'Visible en la ficha de la película y feed social'
                    : 'Visible únicamente para tus amigos mutuos'}
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={() => setIsCommunity(!isCommunity)}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
                isCommunity
                  ? 'bg-emerald-950/60 text-emerald-400 border border-emerald-500/40'
                  : 'bg-purple-950/60 text-purple-400 border border-purple-500/40'
              }`}
            >
              {isCommunity ? 'Comunidad' : 'Solo Amigos'}
            </button>
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

