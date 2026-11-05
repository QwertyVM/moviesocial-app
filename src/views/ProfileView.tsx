"use client";

import React, { useState, useEffect } from 'react';
import { User, Review, UserLocation, Movie } from '../types';
import { api } from '../services/api';
import { AVAILABLE_CITIES, CURATED_MOVIES } from '../data/curatedMovies';
import {
  User as UserIcon,
  MapPin,
  Sparkles,
  Edit2,
  Star,
  Film,
  Calendar,
  X,
  Check,
  Award,
} from 'lucide-react';

interface ProfileViewProps {
  currentUser: User;
  onUpdateUser: (updated: User) => void;
  onSelectMovieById: (movieId: string) => void;
}

export const ProfileView: React.FC<ProfileViewProps> = ({
  currentUser,
  onUpdateUser,
  onSelectMovieById,
}) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [activeTab, setActiveTab] = useState<'reviews' | 'favorites'>('reviews');
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  // Edit form states
  const [displayName, setDisplayName] = useState(currentUser.displayName);
  const [username, setUsername] = useState(currentUser.username);
  const [bio, setBio] = useState(currentUser.bio);
  const [selectedCity, setSelectedCity] = useState(currentUser.location.city);

  const loadProfile = async () => {
    const revs = await api.getReviews();
    setReviews(revs.filter((r) => r.userId === currentUser.id));
  };

  useEffect(() => {
    loadProfile();
  }, [currentUser]);

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    const loc = AVAILABLE_CITIES.find((c) => c.city === selectedCity) || currentUser.location;
    const updated = api.updateUser({
      displayName,
      username: username.startsWith('@') ? username : `@${username}`,
      bio,
      location: loc,
    });
    onUpdateUser(updated);
    setIsEditModalOpen(false);
  };

  const handleTogglePremium = () => {
    const updated = api.updateUser({
      isPremium: !currentUser.isPremium,
    });
    onUpdateUser(updated);
  };

  const favoriteMovies = CURATED_MOVIES.slice(0, 4);

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex flex-col gap-8">
      {/* Profile Header Card */}
      <div className="relative p-6 sm:p-8 rounded-3xl bg-cinema-card border border-cinema-border shadow-2xl overflow-hidden flex flex-col md:flex-row items-center md:items-start gap-6">
        {/* Glow behind avatar */}
        <div className="absolute top-0 left-12 w-48 h-48 bg-cinema-gold/10 rounded-full blur-3xl pointer-events-none" />

        {/* Avatar */}
        <div className="relative flex-shrink-0">
          <img
            src={currentUser.avatarUrl}
            alt={currentUser.displayName}
            className="w-24 h-24 sm:w-28 sm:h-28 rounded-full object-cover border-2 border-cinema-gold shadow-xl"
          />
          {currentUser.isPremium && (
            <div
              className="absolute -bottom-1 -right-1 p-1.5 rounded-full bg-cinema-gold text-black shadow-lg"
              title="Cinéfilo Pro"
            >
              <Sparkles className="w-4 h-4 fill-black" />
            </div>
          )}
        </div>

        {/* Info */}
        <div className="flex flex-col items-center md:items-start text-center md:text-left flex-grow gap-2">
          <div className="flex flex-wrap items-center justify-center md:justify-start gap-2.5">
            <h1 className="text-xl sm:text-2xl font-extrabold text-white">
              {currentUser.displayName}
            </h1>
            <span className="text-xs font-mono text-cinema-textMuted">{currentUser.username}</span>
            {currentUser.isPremium && (
              <span className="px-2.5 py-0.5 rounded-full bg-cinema-gold/15 text-cinema-gold border border-cinema-gold/30 text-[10px] font-bold uppercase tracking-wider flex items-center gap-1">
                <Sparkles className="w-3 h-3" /> Cinéfilo Pro
              </span>
            )}
          </div>

          <p className="text-xs sm:text-sm text-gray-300 max-w-xl font-normal leading-relaxed">
            {currentUser.bio}
          </p>

          <div className="flex flex-wrap items-center justify-center md:justify-start gap-4 text-xs text-cinema-textSecondary mt-2">
            <span className="flex items-center gap-1.5">
              <MapPin className="w-3.5 h-3.5 text-cinema-gold" />
              <span>
                {currentUser.location.flagEmoji} {currentUser.location.city}, {currentUser.location.country}
              </span>
            </span>
            <span className="flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-cinema-textMuted" />
              <span>Miembro desde 2024</span>
            </span>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col gap-2 flex-shrink-0 w-full sm:w-auto">
          <button
            onClick={() => setIsEditModalOpen(true)}
            className="px-4 py-2 rounded-xl bg-cinema-surface hover:bg-cinema-cardHover border border-cinema-border text-white text-xs font-semibold flex items-center justify-center gap-2 transition-colors shadow"
          >
            <Edit2 className="w-3.5 h-3.5 text-cinema-gold" />
            <span>Editar Perfil</span>
          </button>

          <button
            onClick={handleTogglePremium}
            className={`px-4 py-2 rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-colors ${
              currentUser.isPremium
                ? 'bg-cinema-gold/15 text-cinema-gold border border-cinema-gold/40'
                : 'bg-cinema-gold hover:bg-amber-400 text-black font-bold shadow'
            }`}
          >
            <Award className="w-3.5 h-3.5" />
            <span>{currentUser.isPremium ? 'Membresía Pro Activa' : 'Activar Cinéfilo Pro'}</span>
          </button>
        </div>
      </div>

      {/* Statistics Counter */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="p-4 rounded-2xl bg-cinema-card border border-cinema-border flex flex-col items-center justify-center">
          <span className="text-2xl font-bold font-mono text-cinema-gold">{reviews.length}</span>
          <span className="text-xs text-cinema-textMuted mt-1">Reseñas Escritas</span>
        </div>
        <div className="p-4 rounded-2xl bg-cinema-card border border-cinema-border flex flex-col items-center justify-center">
          <span className="text-2xl font-bold font-mono text-indigo-400">4</span>
          <span className="text-xs text-cinema-textMuted mt-1">Amigos en el Círculo</span>
        </div>
        <div className="p-4 rounded-2xl bg-cinema-card border border-cinema-border flex flex-col items-center justify-center">
          <span className="text-2xl font-bold font-mono text-emerald-400">3</span>
          <span className="text-xs text-cinema-textMuted mt-1">Cineclubs Activos</span>
        </div>
        <div className="p-4 rounded-2xl bg-cinema-card border border-cinema-border flex flex-col items-center justify-center">
          <span className="text-2xl font-bold font-mono text-purple-400">4.8★</span>
          <span className="text-xs text-cinema-textMuted mt-1">Promedio Calificaciones</span>
        </div>
      </div>

      {/* Tabs: Mis Reseñas vs Favoritos */}
      <div className="flex flex-col gap-4">
        <div className="flex items-center gap-2 border-b border-cinema-border pb-3">
          <button
            onClick={() => setActiveTab('reviews')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'reviews'
                ? 'bg-cinema-card text-cinema-gold border border-cinema-border shadow'
                : 'text-cinema-textSecondary hover:text-white'
            }`}
          >
            Mis Reseñas ({reviews.length})
          </button>
          <button
            onClick={() => setActiveTab('favorites')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'favorites'
                ? 'bg-cinema-card text-cinema-gold border border-cinema-border shadow'
                : 'text-cinema-textSecondary hover:text-white'
            }`}
          >
            Películas Guardadas & Favoritos
          </button>
        </div>

        {/* Content */}
        {activeTab === 'reviews' ? (
          reviews.length > 0 ? (
            <div className="flex flex-col gap-3">
              {reviews.map((r) => (
                <div
                  key={r.id}
                  className="p-4 rounded-2xl bg-cinema-card border border-cinema-border hover:border-cinema-borderHover transition-colors flex items-start justify-between gap-4"
                >
                  <div className="flex items-start gap-4">
                    {r.moviePosterUrl && (
                      <img
                        src={r.moviePosterUrl}
                        alt={r.movieTitle}
                        onClick={() => onSelectMovieById(r.movieId)}
                        className="w-12 h-16 rounded-xl object-cover cursor-pointer hover:scale-105 transition-transform border border-cinema-border"
                      />
                    )}
                    <div className="flex flex-col gap-1">
                      <h3
                        onClick={() => onSelectMovieById(r.movieId)}
                        className="text-sm font-bold text-white hover:text-cinema-gold cursor-pointer transition-colors"
                      >
                        {r.movieTitle} {r.movieReleaseYear && `(${r.movieReleaseYear})`}
                      </h3>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold font-mono text-cinema-gold flex items-center gap-1">
                          <Star className="w-3 h-3 fill-cinema-gold" />
                          {r.rating.toFixed(1)} / 5.0
                        </span>
                        <span className="text-[10px] text-cinema-textMuted">
                          {new Date(r.createdAt).toLocaleDateString()}
                        </span>
                      </div>
                      <p className="text-xs text-gray-300 mt-1">{r.comment}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-8 text-center rounded-2xl bg-cinema-card border border-cinema-border text-xs text-cinema-textMuted">
              Aún no has escrito reseñas. Abre cualquier película de la cartelera o clásicos para calificarla.
            </div>
          )
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {favoriteMovies.map((m) => (
              <div
                key={m.id}
                onClick={() => onSelectMovieById(m.id)}
                className="group relative rounded-2xl bg-cinema-card border border-cinema-border overflow-hidden cursor-pointer hover:border-cinema-gold/40 transition-all hover:-translate-y-1"
              >
                <div className="aspect-[2/3] w-full">
                  <img
                    src={m.posterURL}
                    alt={m.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  />
                </div>
                <div className="p-2.5">
                  <h4 className="text-xs font-bold text-white truncate">{m.title}</h4>
                  <span className="text-[10px] text-cinema-textMuted">{m.releaseYear}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Edit Profile Modal */}
      {isEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-cinema-card border border-cinema-border p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between pb-2 border-b border-cinema-border">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <Edit2 className="w-4 h-4 text-cinema-gold" />
                Editar Perfil Cinéfilo
              </h3>
              <button
                onClick={() => setIsEditModalOpen(false)}
                className="text-cinema-textMuted hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <form onSubmit={handleSaveProfile} className="flex flex-col gap-4">
              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Nombre para mostrar
                </label>
                <input
                  type="text"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  required
                  className="w-full mt-1 px-3.5 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white outline-none focus:border-cinema-gold"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Nombre de Usuario (@usuario)
                </label>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                  className="w-full mt-1 px-3.5 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white outline-none focus:border-cinema-gold font-mono"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Biografía
                </label>
                <textarea
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  rows={3}
                  className="w-full mt-1 px-3.5 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white outline-none focus:border-cinema-gold resize-none"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-cinema-textSecondary uppercase">
                  Ciudad Predeterminada (Cartelera)
                </label>
                <select
                  value={selectedCity}
                  onChange={(e) => setSelectedCity(e.target.value)}
                  className="w-full mt-1 px-3.5 py-2 rounded-xl bg-cinema-surface border border-cinema-border text-xs text-white outline-none focus:border-cinema-gold"
                >
                  {AVAILABLE_CITIES.map((c) => (
                    <option key={c.city} value={c.city}>
                      {c.flagEmoji} {c.city} ({c.country})
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-4 py-2 text-xs text-cinema-textSecondary"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl bg-cinema-gold text-black font-bold text-xs"
                >
                  Guardar Cambios
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
