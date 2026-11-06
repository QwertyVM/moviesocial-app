"use client";

import React, { useState, useEffect } from "react";
import { User, Movie, Friend, UserLocation } from "@/types";
import { api } from "@/services/api";
import { Navbar } from "@/components/common/Navbar";
import { CatalogView } from "@/views/CatalogView";
import { ArchiveView } from "@/views/ArchiveView";
import { FriendsFeedView } from "@/views/FriendsFeedView";
import { ChatsView } from "@/views/ChatsView";
import { ProfileView } from "@/views/ProfileView";
import { MovieDetailModal } from "@/components/movies/MovieDetailModal";
import { SubscriptionModal } from "@/components/subscription/SubscriptionModal";
import { AuthModal } from "@/components/auth/AuthModal";
import { AuthGateCard } from "@/components/auth/AuthGateCard";
import { getUserById } from "@/actions/users";
import { Users, MessageSquare, User as UserIcon } from "lucide-react";

export default function Home() {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [currentLocation, setCurrentLocation] = useState<UserLocation>({
    city: "Lima",
    country: "Perú",
    countryCode: "PE",
    flagEmoji: "🇵🇪",
    isLocal: true,
    area: "Lima",
  });

  const [activeTab, setActiveTab] = useState<"catalog" | "archive" | "feed" | "chats" | "profile">("catalog");
  const [lens, setLens] = useState<"friends" | "global">("friends");
  const [initialCatalogCategory, setInitialCatalogCategory] = useState<"nowPlaying" | "classics">("nowPlaying");
  const [selectedMovie, setSelectedMovie] = useState<Movie | null>(null);
  const [chatTargetFriend, setChatTargetFriend] = useState<Friend | null>(null);
  const [dbStatus, setDbStatus] = useState<{ online: boolean; database?: string }>({
    online: true,
    database: "Neon DB (PostgreSQL Cloud)",
  });

  // Auth modal state
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [authModalMode, setAuthModalMode] = useState<"login" | "register">("login");
  const [authReason, setAuthReason] = useState<string | undefined>();

  // Subscription modal state
  const [isSubscriptionModalOpen, setIsSubscriptionModalOpen] = useState(false);
  const [subscriptionReason, setSubscriptionReason] = useState<string | undefined>();

  useEffect(() => {
    // Sincronizar usuario guardado en localStorage tras la hidratación inicial
    const storedUser = api.getCurrentUser();
    if (storedUser) {
      setCurrentUser(storedUser);
      if (storedUser.location) {
        setCurrentLocation(storedUser.location);
      }
    }

    // Sincronizar tab o película desde parámetros de URL si existen
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const tabParam = params.get("tab");
      if (tabParam === "classics" || tabParam === "archive") {
        setActiveTab("archive");
      } else if (tabParam === "feed" || tabParam === "chats" || tabParam === "profile") {
        setActiveTab(tabParam);
      }

      const movieParam = params.get("movie");
      if (movieParam) {
        api.getMovieById(movieParam).then((m) => {
          if (m) setSelectedMovie(m);
        });
      }

      const authParam = params.get("auth");
      if (authParam === "login" || authParam === "register") {
        setAuthModalMode(authParam);
        setIsAuthModalOpen(true);
      }

      const asUserParam = params.get("asUser");
      if (asUserParam) {
        getUserById(asUserParam).then((u) => {
          if (u) {
            api.login(u);
            setCurrentUser(u);
            if (u.location) setCurrentLocation(u.location);
          }
        });
      }
    }
  }, []);

  const handleOpenAuthModal = (mode: "login" | "register" = "login", reason?: string) => {
    setAuthModalMode(mode);
    setAuthReason(reason);
    setIsAuthModalOpen(true);
  };

  const handleLoginSuccess = (user: User) => {
    setCurrentUser(user);
    if (user.location) {
      setCurrentLocation(user.location);
    }
  };

  const handleLogout = () => {
    api.logout();
    setCurrentUser(null);
  };

  const handleSelectCity = (location: UserLocation) => {
    setCurrentLocation(location);
    if (currentUser) {
      const updated = api.setUserCity(location);
      if (updated) setCurrentUser(updated);
    }
  };

  const handleSelectMovieById = async (movieId: string) => {
    const found = await api.getMovieById(movieId);
    if (found) {
      setSelectedMovie(found);
    }
  };

  const handleOpenChatWithFriend = (friend: Friend) => {
    setChatTargetFriend(friend);
    setActiveTab("chats");
  };

  const handleShareInChat = (movie: Movie) => {
    setSelectedMovie(null);
    setActiveTab("chats");
  };

  const handleOpenSubscriptionModal = (reason?: string) => {
    if (!currentUser) {
      handleOpenAuthModal("login", "Inicia sesión para suscribirte o cambiar tu plan de comunidad.");
      return;
    }
    setSubscriptionReason(reason);
    setIsSubscriptionModalOpen(true);
  };

  const handleSubscribe = () => {
    const updated = api.updateUser({ isPremium: true });
    if (updated) setCurrentUser(updated);
  };

  const handleCancelSubscription = () => {
    const updated = api.updateUser({ isPremium: false });
    if (updated) setCurrentUser(updated);
  };

  return (
    <div
      className={`bg-[#050608] text-gray-100 flex flex-col relative selection:bg-amber-500/30 selection:text-amber-200 ${
        activeTab === "catalog"
          ? "h-screen overflow-hidden"
          : "min-h-screen pb-16 overflow-x-hidden"
      }`}
    >
      {/* Atmósfera de Sala de Cine: Haz de Luz de Proyector y Resplandor de Gran Pantalla */}
      <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
        {/* Foco de Proyector Cenital proyectando sobre la pantalla */}
        <div className="absolute -top-32 left-1/2 -translate-x-1/2 w-[1000px] h-[550px] bg-[radial-gradient(ellipse_at_top,rgba(245,158,11,0.12),rgba(217,119,6,0.04)_45%,transparent_70%)] blur-2xl opacity-80" />
        {/* Haz cónico de luz cinematrográfica */}
        <div className="absolute -top-24 left-1/2 -translate-x-1/2 w-[450px] h-[480px] bg-gradient-to-b from-amber-200/10 via-amber-400/5 to-transparent blur-3xl opacity-60" />
        {/* Reflejos laterales aterciopelados estilo butacas de cine */}
        <div className="absolute top-1/4 -left-48 w-96 h-96 bg-rose-950/15 rounded-full blur-[130px]" />
        <div className="absolute top-1/3 -right-48 w-96 h-96 bg-amber-950/15 rounded-full blur-[130px]" />
        {/* Viñeta perimetral de sala a oscuras */}
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,transparent_40%,rgba(3,4,6,0.9)_100%)]" />
      </div>

      {/* Top Navbar */}
      <Navbar
        activeTab={activeTab}
        onSelectTab={(tab) => {
          setActiveTab(tab);
          if (tab !== "chats") setChatTargetFriend(null);
        }}
        currentUser={currentUser}
        currentLocation={currentLocation}
        onSelectCity={handleSelectCity}
        onOpenSubscriptionModal={handleOpenSubscriptionModal}
        onOpenAuthModal={handleOpenAuthModal}
        onLogout={handleLogout}
      />

      {/* Main Content Area */}
      <main className={`relative z-10 flex-grow ${activeTab === 'catalog' ? 'overflow-hidden flex flex-col h-[calc(100vh-4rem)]' : ''}`}>
        {activeTab === "catalog" && (
          <CatalogView
            currentUser={currentUser}
            location={currentLocation}
            onSelectMovie={(movie) => setSelectedMovie(movie)}
            initialCategory={initialCatalogCategory}
            lens={lens}
            onOpenAuthModal={handleOpenAuthModal}
            onOpenChatWithFriend={handleOpenChatWithFriend}
          />
        )}

        {activeTab === "archive" && (
          <ArchiveView
            currentUser={currentUser}
            location={currentLocation}
            onSelectMovie={(movie) => setSelectedMovie(movie)}
            onOpenAuthModal={handleOpenAuthModal}
          />
        )}

        {activeTab === "feed" &&
          (currentUser ? (
            <FriendsFeedView
              currentUser={currentUser}
              onSelectMovieById={handleSelectMovieById}
              onOpenChatWithFriend={handleOpenChatWithFriend}
              onOpenSubscriptionModal={handleOpenSubscriptionModal}
              lens={lens}
              onToggleLens={setLens}
            />
          ) : (
            <AuthGateCard
              title="Muro Social y Feed de Amigos"
              subtitle="Conecta con cinéfilos reales, lee sus críticas y descubre qué películas están viendo y calificando tus amigos."
              icon={<Users className="w-8 h-8 sm:w-10 sm:h-10 text-cinema-gold" />}
              onOpenAuth={() =>
                handleOpenAuthModal(
                  "register",
                  "Crea tu cuenta cinéfila o inicia sesión para ver las críticas y actividad de tus amigos."
                )
              }
              onGoToCatalog={() => setActiveTab("catalog")}
            />
          ))}

        {activeTab === "chats" &&
          (currentUser ? (
            <ChatsView
              currentUser={currentUser}
              onSelectMovieById={handleSelectMovieById}
              initialFriendForChat={chatTargetFriend}
              onOpenSubscriptionModal={handleOpenSubscriptionModal}
            />
          ) : (
            <AuthGateCard
              title="Chats Privados y Cineclubs"
              subtitle="Únete a comunidades de debate, crea cineclubs con código de invitación y comparte películas directamente con tus amigos."
              icon={<MessageSquare className="w-8 h-8 sm:w-10 sm:h-10 text-cinema-gold" />}
              onOpenAuth={() =>
                handleOpenAuthModal(
                  "login",
                  "Inicia sesión para chatear en tiempo real, compartir fichas de cine y unirte a cineclubs."
                )
              }
              onGoToCatalog={() => setActiveTab("catalog")}
            />
          ))}

        {activeTab === "profile" &&
          (currentUser ? (
            <ProfileView
              currentUser={currentUser}
              onUpdateUser={setCurrentUser}
              onSelectMovieById={handleSelectMovieById}
              onOpenSubscriptionModal={handleOpenSubscriptionModal}
            />
          ) : (
            <AuthGateCard
              title="Tu Perfil Cinéfilo y Suscripción"
              subtitle="Lleva el registro de tus películas vistas, administra tus críticas públicas o privadas y activa tu suscripción Pro."
              icon={<UserIcon className="w-8 h-8 sm:w-10 sm:h-10 text-cinema-gold" />}
              onOpenAuth={() =>
                handleOpenAuthModal(
                  "login",
                  "Inicia sesión para gestionar tu perfil, tus reseñas y tu plan de suscripción."
                )
              }
              onGoToCatalog={() => setActiveTab("catalog")}
            />
          ))}
      </main>

      {/* Global Movie Detail Modal */}
      <MovieDetailModal
        movie={selectedMovie}
        isOpen={!!selectedMovie}
        onClose={() => setSelectedMovie(null)}
        currentUser={currentUser}
        onShareInChat={handleShareInChat}
        onOpenSubscriptionModal={handleOpenSubscriptionModal}
        onRequireLogin={(reason) => handleOpenAuthModal("login", reason)}
      />

      {/* Subscription Modal for Monthly Plan */}
      {currentUser && (
        <SubscriptionModal
          isOpen={isSubscriptionModalOpen}
          onClose={() => setIsSubscriptionModalOpen(false)}
          currentUser={currentUser}
          onSubscribe={handleSubscribe}
          onCancelSubscription={handleCancelSubscription}
          triggerReason={subscriptionReason}
        />
      )}

      {/* Login & Register Modal */}
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
        onSuccess={handleLoginSuccess}
        initialMode={authModalMode}
        reason={authReason}
        defaultLocation={currentLocation}
      />
    </div>
  );
}
