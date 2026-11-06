"use client";

import React, { useState, useEffect } from 'react';
import { Review, Friend, User, Movie, ReviewComment } from '../types';
import { api } from '../services/api';
import {
  Heart,
  MessageCircle,
  Share2,
  UserPlus,
  Send,
  Sparkles,
  Users,
  Search,
  MessageSquare,
  Star,
  Globe,
  Lock,
  ArrowRight,
} from 'lucide-react';

interface FriendsFeedViewProps {
  currentUser: User;
  onSelectMovieById: (movieId: string) => void;
  onOpenChatWithFriend: (friend: Friend) => void;
  onOpenSubscriptionModal?: (reason?: string) => void;
  lens?: 'friends' | 'global';
  onToggleLens?: (lens: 'friends' | 'global') => void;
}

export const FriendsFeedView: React.FC<FriendsFeedViewProps> = ({
  currentUser,
  onSelectMovieById,
  onOpenChatWithFriend,
  onOpenSubscriptionModal,
  lens = 'friends',
  onToggleLens,
}) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [friends, setFriends] = useState<Friend[]>([]);
  const [feedScope, setFeedScope] = useState<'friends' | 'global'>(lens);
  const [searchFriendText, setSearchFriendText] = useState('');
  const [activeCommentReviewId, setActiveCommentReviewId] = useState<string | null>(null);
  const [commentInputs, setCommentInputs] = useState<Record<string, string>>({});
  const [addingFriend, setAddingFriend] = useState(false);

  useEffect(() => {
    setFeedScope(lens);
  }, [lens]);

  const loadData = async () => {
    const revs = await api.getReviews();
    const frs = await api.getFriends();
    setReviews(revs);
    setFriends(frs);
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleLike = async (reviewId: string) => {
    const targetRev = reviews.find((r) => r.id === reviewId);
    if (targetRev?.isCommunity && !currentUser.isPremium) {
      onOpenSubscriptionModal?.(
        'Para dar me gusta e interactuar con la comunidad global necesitas una suscripción mensual. En el Plan Base solo puedes interactuar con amigos.'
      );
      return;
    }
    const updated = await api.toggleLikeReview(reviewId);
    if (updated) {
      setReviews(reviews.map((r) => (r.id === reviewId ? updated : r)));
    }
  };

  const handleAddComment = async (reviewId: string) => {
    const targetRev = reviews.find((r) => r.id === reviewId);
    if (targetRev?.isCommunity && !currentUser.isPremium) {
      onOpenSubscriptionModal?.(
        'Para comentar e interactuar con la comunidad global necesitas una suscripción mensual. En el Plan Base solo puedes interactuar con amigos.'
      );
      return;
    }
    const text = commentInputs[reviewId]?.trim();
    if (!text) return;
    const updated = await api.addCommentToReview(reviewId, text);
    if (updated) {
      setReviews(reviews.map((r) => (r.id === reviewId ? updated : r)));
      setCommentInputs({ ...commentInputs, [reviewId]: '' });
    }
  };

  const handleAddFriend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchFriendText.trim()) return;
    setAddingFriend(true);
    try {
      const added = await api.addFriend(searchFriendText.trim());
      setFriends([...friends, added]);
      setSearchFriendText('');
    } finally {
      setAddingFriend(false);
    }
  };

  const friendIds = new Set(friends.map((f) => f.id));
  const filteredReviews = reviews.filter((r) => {
    if (feedScope === 'friends') {
      return !r.isCommunity || r.userId === currentUser.id || friendIds.has(r.userId);
    } else {
      return r.isCommunity;
    }
  });

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left 2 Columns: Activity Feed */}
        <div className="lg:col-span-2 flex flex-col gap-5">
          {/* Feed Header with Scope Switcher */}
          <div className="p-4 sm:p-5 rounded-3xl bg-cinema-card border border-cinema-border flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-xl">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-2xl flex items-center justify-center ${
                feedScope === 'friends' ? 'bg-indigo-950/60 border border-indigo-500/30 text-indigo-400' : 'bg-amber-950/60 border border-cinema-gold/40 text-cinema-gold'
              }`}>
                {feedScope === 'friends' ? <Users className="w-5 h-5" /> : <Globe className="w-5 h-5" />}
              </div>
              <div>
                <h1 className="text-base sm:text-lg font-bold text-white">
                  {feedScope === 'friends' ? 'Muro de Amigos' : 'Comunidad Global (Mundo)'}
                </h1>
                <p className="text-xs text-cinema-textMuted">
                  {feedScope === 'friends'
                    ? 'Micro-reseñas y calificaciones exclusivas de tu círculo cercano (Plan Base)'
                    : 'Críticas abiertas compartidas por cinéfilos de todo el mundo'}
                </p>
              </div>
            </div>

            {/* Scope Switcher */}
            <div className="flex items-center bg-cinema-surface p-1 rounded-2xl border border-cinema-border flex-shrink-0">
              <button
                onClick={() => setFeedScope('friends')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                  feedScope === 'friends'
                    ? 'bg-cinema-card text-purple-300 shadow border border-cinema-border'
                    : 'text-cinema-textSecondary hover:text-white'
                }`}
              >
                <Users className="w-3.5 h-3.5" />
                <span>Amigos</span>
              </button>

              <button
                onClick={() => setFeedScope('global')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                  feedScope === 'global'
                    ? 'bg-cinema-card text-cinema-gold shadow border border-cinema-border'
                    : 'text-cinema-textSecondary hover:text-white'
                }`}
              >
                <Globe className="w-3.5 h-3.5" />
                <span>Mundo</span>
              </button>
            </div>
          </div>

          {/* Prompt banner if in Global and not Subscribed */}
          {feedScope === 'global' && !currentUser.isPremium && (
            <div className="p-4 rounded-2xl bg-gradient-to-r from-amber-950/30 via-cinema-card to-cinema-card border border-cinema-gold/40 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 shadow-lg">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-xl bg-amber-950/70 border border-cinema-gold/30 text-cinema-gold flex-shrink-0">
                  <Lock className="w-4 h-4" />
                </div>
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-white">Interacción con la Comunidad Global</span>
                  <span className="text-[11px] text-cinema-textMuted max-w-lg">
                    Con tu Plan Base actual puedes leer el muro mundial, pero tus comentarios solo se comparten con amigos. Activa la Suscripción Mensual (S/ 14.90/mes) para que tus opiniones las lea el mundo entero e interactuar con la comunidad.
                  </span>
                </div>
              </div>
              <button
                onClick={() =>
                  onOpenSubscriptionModal?.(
                    'Para que tus comentarios se puedan ver al mundo e interactuar con la comunidad, necesitas la suscripción mensual. En el Plan Base solo puedes interactuar con amigos.'
                  )
                }
                className="px-4 py-2 rounded-xl bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold transition-all shadow-md flex items-center gap-1.5 whitespace-nowrap flex-shrink-0"
              >
                <Sparkles className="w-3.5 h-3.5" />
                <span>Activar Suscripción Mensual</span>
              </button>
            </div>
          )}

          {/* Feed Items */}
          <div className="flex flex-col gap-4">
            {filteredReviews.length === 0 ? (
              <div className="p-10 rounded-3xl bg-cinema-card border border-cinema-border text-center flex flex-col items-center justify-center gap-3 shadow-lg">
                <div className="w-14 h-14 rounded-2xl bg-cinema-surface border border-cinema-border flex items-center justify-center text-cinema-gold shadow-inner">
                  <MessageSquare className="w-7 h-7 opacity-80" />
                </div>
                <h3 className="text-sm font-bold text-white">
                  {feedScope === 'friends'
                    ? 'Aún no hay reseñas de tus amigos'
                    : 'Aún no hay reseñas de la comunidad'}
                </h3>
                <p className="text-xs text-cinema-textSecondary max-w-sm leading-relaxed">
                  {feedScope === 'friends'
                    ? 'Sé el primero en calificar una película en cartelera o conecta con más cinéfilos en el directorio lateral.'
                    : 'Las reseñas globales de la comunidad aparecerán aquí a medida que los usuarios opinen sobre estrenos.'}
                </p>
              </div>
            ) : (
              filteredReviews.map((r) => {
              const isCommentOpen = activeCommentReviewId === r.id;
              return (
                <div
                  key={r.id}
                  className="p-5 rounded-3xl bg-cinema-card border border-cinema-border hover:border-cinema-borderHover transition-all shadow-lg flex flex-col gap-4"
                >
                  {/* Review Author & Header */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <img
                        src={r.userAvatarUrl || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'}
                        alt={r.userName}
                        className="w-10 h-10 rounded-full object-cover border border-cinema-border"
                      />
                      <div className="flex flex-col">
                        <div className="flex items-center gap-1.5">
                          <span className="text-sm font-bold text-white">{r.userName}</span>
                          {r.userIsPremium && (
                            <span className="px-1.5 py-0.2 rounded-full bg-cinema-gold/20 text-cinema-gold text-[9px] font-bold border border-cinema-gold/30">
                              Pro
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-2 text-[11px] text-cinema-textMuted">
                          <span>
                            {new Date(r.createdAt).toLocaleDateString('es-ES', {
                              day: 'numeric',
                              month: 'short',
                            })}
                          </span>
                          <span>•</span>
                          {r.isCommunity ? (
                            <span className="text-cinema-gold flex items-center gap-1 font-semibold text-[10px]">
                              <Globe className="w-2.5 h-2.5" /> Comunidad Global
                            </span>
                          ) : (
                            <span className="text-purple-400 flex items-center gap-1 font-semibold text-[10px]">
                              <Users className="w-2.5 h-2.5" /> Solo Amigos
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Star Rating Badge */}
                    <div className="flex items-center gap-1.5 px-3 py-1 rounded-xl bg-cinema-surface border border-cinema-gold/30 text-cinema-gold font-mono font-bold text-xs">
                      <Star className="w-3.5 h-3.5 fill-cinema-gold text-cinema-gold" />
                      <span>{r.rating.toFixed(1)}</span>
                    </div>
                  </div>

                  {/* Movie Reference Card */}
                  <div
                    onClick={() => onSelectMovieById(r.movieId)}
                    className="p-3 rounded-2xl bg-cinema-surface hover:bg-cinema-surface/80 border border-cinema-border cursor-pointer transition-colors flex items-center justify-between gap-3 group"
                  >
                    <div className="flex items-center gap-3">
                      {r.moviePosterUrl && (
                        <img
                          src={r.moviePosterUrl}
                          alt={r.movieTitle}
                          className="w-10 h-14 rounded-lg object-cover border border-cinema-border group-hover:scale-105 transition-transform"
                        />
                      )}
                      <div>
                        <span className="text-xs text-cinema-textMuted uppercase font-mono tracking-wider">
                          Película calificada
                        </span>
                        <h4 className="text-sm font-bold text-white group-hover:text-cinema-gold transition-colors">
                          {r.movieTitle} {r.movieReleaseYear && `(${r.movieReleaseYear})`}
                        </h4>
                      </div>
                    </div>
                    <span className="text-xs font-semibold text-cinema-gold opacity-0 group-hover:opacity-100 transition-opacity pr-2">
                      Ver Ficha →
                    </span>
                  </div>

                  {/* Review Text */}
                  <p className="text-sm text-gray-200 leading-relaxed font-normal whitespace-pre-wrap">
                    {r.comment}
                  </p>

                  {/* Actions Bar */}
                  <div className="flex items-center justify-between pt-2 border-t border-cinema-border/60">
                    <div className="flex items-center gap-2">
                      {/* Like button */}
                      <button
                        onClick={() => handleLike(r.id)}
                        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium transition-colors ${
                          r.isLikedByMe
                            ? 'bg-rose-950/60 text-rose-400 border border-rose-500/40 font-semibold'
                            : 'bg-cinema-surface hover:bg-cinema-cardHover text-cinema-textSecondary border border-cinema-border'
                        }`}
                      >
                        <Heart
                          className={`w-3.5 h-3.5 ${
                            r.isLikedByMe ? 'fill-rose-400 text-rose-400' : ''
                          }`}
                        />
                        <span>{r.likesCount}</span>
                      </button>

                      {/* Comments toggle button */}
                      <button
                        onClick={() =>
                          setActiveCommentReviewId(isCommentOpen ? null : r.id)
                        }
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium bg-cinema-surface hover:bg-cinema-cardHover text-cinema-textSecondary border border-cinema-border transition-colors"
                      >
                        <MessageCircle className="w-3.5 h-3.5 text-cinema-textMuted" />
                        <span>{r.comments?.length || 0} comentarios</span>
                      </button>
                    </div>

                    <button
                      onClick={() => onSelectMovieById(r.movieId)}
                      className="text-xs font-medium text-cinema-textMuted hover:text-white transition-colors"
                    >
                      Ver en cartelera
                    </button>
                  </div>

                  {/* Comments Section (Collapsible) */}
                  {isCommentOpen && (
                    <div className="pt-3 border-t border-cinema-border flex flex-col gap-3">
                      {r.comments && r.comments.length > 0 && (
                        <div className="flex flex-col gap-2">
                          {r.comments.map((c: ReviewComment) => (
                            <div
                              key={c.id}
                              className="p-3 rounded-xl bg-cinema-surface border border-cinema-border flex flex-col gap-1 text-xs"
                            >
                              <div className="flex items-center justify-between">
                                <span className="font-bold text-white">{c.userName}</span>
                                <span className="text-[10px] text-cinema-textMuted">
                                  {new Date(c.createdAt).toLocaleTimeString('es-ES', {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  })}
                                </span>
                              </div>
                              <p className="text-gray-300">{c.text}</p>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Add comment input / Subscription gate */}
                      {r.isCommunity && !currentUser.isPremium ? (
                        <div className="p-3 rounded-xl bg-cinema-card border border-cinema-gold/30 flex items-center justify-between gap-3">
                          <div className="flex items-center gap-2 text-xs text-cinema-textSecondary">
                            <Lock className="w-4 h-4 text-cinema-gold flex-shrink-0" />
                            <span>
                              En el <strong>Plan Base</strong> solo puedes comentar a tus amigos. Activa la suscripción para interactuar con la comunidad.
                            </span>
                          </div>
                          <button
                            onClick={() =>
                              onOpenSubscriptionModal?.(
                                'Para comentar e interactuar con la comunidad global necesitas una suscripción mensual. En el Plan Base solo puedes interactuar con amigos.'
                              )
                            }
                            className="px-3 py-1.5 rounded-lg bg-cinema-gold hover:bg-amber-400 text-black text-xs font-bold transition-all whitespace-nowrap shadow"
                          >
                            Activar Pro
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center gap-2">
                          <input
                            type="text"
                            value={commentInputs[r.id] || ''}
                            onChange={(e) =>
                              setCommentInputs({ ...commentInputs, [r.id]: e.target.value })
                            }
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') handleAddComment(r.id);
                            }}
                            placeholder="Escribe una respuesta cinéfila..."
                            className="flex-grow px-3 py-2 rounded-xl bg-cinema-surface border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none"
                          />
                          <button
                            onClick={() => handleAddComment(r.id)}
                            className="p-2 rounded-xl bg-cinema-gold text-black hover:bg-amber-400 transition-colors"
                          >
                            <Send className="w-4 h-4" />
                          </button>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            }))}
          </div>
        </div>

        {/* Right Column: Friends Directory & Add Friend */}
        <div className="flex flex-col gap-5">
          {/* Add Friend Card */}
          <div className="p-5 rounded-3xl bg-cinema-card border border-cinema-border flex flex-col gap-4 shadow-lg">
            <div className="flex items-center gap-2">
              <UserPlus className="w-4 h-4 text-cinema-gold" />
              <h2 className="text-sm font-bold text-white uppercase tracking-wider">
                Agregar Cinéfilo
              </h2>
            </div>
            <form onSubmit={handleAddFriend} className="flex flex-col gap-2">
              <div className="relative">
                <input
                  type="text"
                  value={searchFriendText}
                  onChange={(e) => setSearchFriendText(e.target.value)}
                  placeholder="Ej: @lucasromero o nombre"
                  required
                  className="w-full px-3.5 py-2.5 rounded-xl bg-cinema-surface border border-cinema-border focus:border-cinema-gold text-xs text-white placeholder-cinema-textMuted outline-none"
                />
              </div>
              <button
                type="submit"
                disabled={addingFriend || !searchFriendText.trim()}
                className="w-full py-2.5 rounded-xl bg-cinema-gold hover:bg-amber-400 disabled:opacity-50 text-black font-bold text-xs flex items-center justify-center gap-1.5 transition-colors shadow"
              >
                <UserPlus className="w-3.5 h-3.5" />
                <span>{addingFriend ? 'Agregando...' : 'Conectar Amigo'}</span>
              </button>
            </form>
          </div>

          {/* Friends List */}
          <div className="p-5 rounded-3xl bg-cinema-card border border-cinema-border flex flex-col gap-4 shadow-lg">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-bold text-white uppercase tracking-wider">
                Círculo de Amigos ({friends.length})
              </h2>
              <span className="text-[11px] text-cinema-textMuted font-mono">Mutuos</span>
            </div>

            <div className="flex flex-col gap-3">
              {friends.map((f) => (
                <div
                  key={f.id}
                  className="p-3 rounded-2xl bg-cinema-surface border border-cinema-border hover:border-cinema-borderHover transition-colors flex items-center justify-between gap-3"
                >
                  <div className="flex items-center gap-3">
                    <img
                      src={f.avatarUrl}
                      alt={f.displayName}
                      className="w-9 h-9 rounded-full object-cover border border-cinema-border"
                    />
                    <div className="flex flex-col">
                      <span className="text-xs font-bold text-white">{f.displayName}</span>
                      <span className="text-[10px] text-cinema-textMuted font-mono">
                        {f.username} • {f.mutualMoviesCount} pelis
                      </span>
                    </div>
                  </div>

                  <button
                    onClick={() => onOpenChatWithFriend(f)}
                    className="p-2 rounded-xl bg-cinema-card hover:bg-cinema-cardHover text-cinema-gold border border-cinema-border transition-transform hover:scale-105"
                    title={`Chatear con ${f.displayName}`}
                  >
                    <MessageSquare className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};
