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
} from 'lucide-react';

interface FriendsFeedViewProps {
  currentUser: User;
  onSelectMovieById: (movieId: string) => void;
  onOpenChatWithFriend: (friend: Friend) => void;
}

export const FriendsFeedView: React.FC<FriendsFeedViewProps> = ({
  currentUser,
  onSelectMovieById,
  onOpenChatWithFriend,
}) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [friends, setFriends] = useState<Friend[]>([]);
  const [searchFriendText, setSearchFriendText] = useState('');
  const [activeCommentReviewId, setActiveCommentReviewId] = useState<string | null>(null);
  const [commentInputs, setCommentInputs] = useState<Record<string, string>>({});
  const [addingFriend, setAddingFriend] = useState(false);

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
    const updated = await api.toggleLikeReview(reviewId);
    if (updated) {
      setReviews(reviews.map((r) => (r.id === reviewId ? updated : r)));
    }
  };

  const handleAddComment = async (reviewId: string) => {
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

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left 2 Columns: Activity Feed */}
        <div className="lg:col-span-2 flex flex-col gap-5">
          {/* Feed Header */}
          <div className="p-4 sm:p-5 rounded-3xl bg-cinema-card border border-cinema-border flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-indigo-950/60 border border-indigo-500/30 flex items-center justify-center">
                <Users className="w-5 h-5 text-indigo-400" />
              </div>
              <div>
                <h1 className="text-base sm:text-lg font-bold text-white">Actividad de Amigos</h1>
                <p className="text-xs text-cinema-textMuted">Micro-reseñas y calificaciones recientes sin anuncios ni spam</p>
              </div>
            </div>
            <span className="text-xs font-mono px-3 py-1 rounded-full bg-cinema-surface border border-cinema-border text-cinema-textSecondary">
              {reviews.length} reseñas
            </span>
          </div>

          {/* Feed Items */}
          <div className="flex flex-col gap-4">
            {reviews.map((r) => {
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
                        <span className="text-sm font-bold text-white">{r.userName}</span>
                        <span className="text-[11px] text-cinema-textMuted">
                          {new Date(r.createdAt).toLocaleDateString('es-ES', {
                            day: 'numeric',
                            month: 'short',
                          })}
                        </span>
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

                      {/* Add comment input */}
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
                    </div>
                  )}
                </div>
              );
            })}
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
