"use client";

import React, { useState, useEffect } from "react";
import { User, Movie, Friend, UserLocation } from "@/types";
import { api } from "@/services/api";
import { DEFAULT_USER } from "@/data/curatedMovies";
import { Navbar } from "@/components/common/Navbar";
import { CatalogView } from "@/views/CatalogView";
import { FriendsFeedView } from "@/views/FriendsFeedView";
import { ChatsView } from "@/views/ChatsView";
import { ProfileView } from "@/views/ProfileView";
import { MovieDetailModal } from "@/components/movies/MovieDetailModal";
import { SubscriptionModal } from "@/components/subscription/SubscriptionModal";

export default function Home() {
  const [currentUser, setCurrentUser] = useState<User>(DEFAULT_USER);
  const [activeTab, setActiveTab] = useState<"catalog" | "feed" | "chats" | "profile">("catalog");
  const [initialCatalogCategory, setInitialCatalogCategory] = useState<"nowPlaying" | "classics">("nowPlaying");
  const [selectedMovie, setSelectedMovie] = useState<Movie | null>(null);
  const [chatTargetFriend, setChatTargetFriend] = useState<Friend | null>(null);
  const [dbStatus, setDbStatus] = useState<{ online: boolean; database?: string }>({ online: true, database: "Neon DB (PostgreSQL Cloud)" });
  
  // Subscription modal state
  const [isSubscriptionModalOpen, setIsSubscriptionModalOpen] = useState(false);
  const [subscriptionReason, setSubscriptionReason] = useState<string | undefined>();

  useEffect(() => {
    // Sincronizar usuario guardado en localStorage tras la hidratación inicial
    const storedUser = api.getCurrentUser();
    if (storedUser) {
      setCurrentUser(storedUser);
    }

    // Sincronizar tab o película desde parámetros de URL si existen
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const tabParam = params.get("tab");
      if (tabParam === "classics") {
        setActiveTab("catalog");
        setInitialCatalogCategory("classics");
      } else if (tabParam === "feed" || tabParam === "chats" || tabParam === "profile") {
        setActiveTab(tabParam);
      }

      const movieParam = params.get("movie");
      if (movieParam) {
        api.getMovieById(movieParam).then((m) => {
          if (m) setSelectedMovie(m);
        });
      }
    }
  }, []);

  const handleSelectCity = (location: UserLocation) => {
    const updated = api.setUserCity(location);
    setCurrentUser(updated);
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
    setSubscriptionReason(reason);
    setIsSubscriptionModalOpen(true);
  };

  const handleSubscribe = () => {
    const updated = api.updateUser({ isPremium: true });
    setCurrentUser(updated);
  };

  const handleCancelSubscription = () => {
    const updated = api.updateUser({ isPremium: false });
    setCurrentUser(updated);
  };

  return (
    <div className="min-h-screen bg-[#0B0C0E] text-gray-100 flex flex-col pb-20 md:pb-8">
      {/* Top Navbar */}
      <Navbar
        activeTab={activeTab}
        onSelectTab={(tab) => {
          setActiveTab(tab);
          if (tab !== "chats") setChatTargetFriend(null);
        }}
        currentUser={currentUser}
        onSelectCity={handleSelectCity}
        dbStatus={dbStatus}
        onOpenSubscriptionModal={handleOpenSubscriptionModal}
      />

      {/* Main Content Area */}
      <main className="flex-grow">
        {activeTab === "catalog" && (
          <CatalogView
            currentUser={currentUser}
            onSelectMovie={(movie) => setSelectedMovie(movie)}
            initialCategory={initialCatalogCategory}
          />
        )}

        {activeTab === "feed" && (
          <FriendsFeedView
            currentUser={currentUser}
            onSelectMovieById={handleSelectMovieById}
            onOpenChatWithFriend={handleOpenChatWithFriend}
            onOpenSubscriptionModal={handleOpenSubscriptionModal}
          />
        )}

        {activeTab === "chats" && (
          <ChatsView
            currentUser={currentUser}
            onSelectMovieById={handleSelectMovieById}
            initialFriendForChat={chatTargetFriend}
            onOpenSubscriptionModal={handleOpenSubscriptionModal}
          />
        )}

        {activeTab === "profile" && (
          <ProfileView
            currentUser={currentUser}
            onUpdateUser={setCurrentUser}
            onSelectMovieById={handleSelectMovieById}
            onOpenSubscriptionModal={handleOpenSubscriptionModal}
          />
        )}
      </main>

      {/* Global Movie Detail Modal */}
      <MovieDetailModal
        movie={selectedMovie}
        isOpen={!!selectedMovie}
        onClose={() => setSelectedMovie(null)}
        currentUser={currentUser}
        onShareInChat={handleShareInChat}
        onOpenSubscriptionModal={handleOpenSubscriptionModal}
      />

      {/* Subscription Modal for Monthly Plan */}
      <SubscriptionModal
        isOpen={isSubscriptionModalOpen}
        onClose={() => setIsSubscriptionModalOpen(false)}
        currentUser={currentUser}
        onSubscribe={handleSubscribe}
        onCancelSubscription={handleCancelSubscription}
        triggerReason={subscriptionReason}
      />
    </div>
  );
}

