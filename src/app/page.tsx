"use client";

import React, { useState, useEffect } from "react";
import { User, Movie, Friend, UserLocation } from "@/types";
import { api } from "@/services/api";
import { Navbar } from "@/components/common/Navbar";
import { CatalogView } from "@/views/CatalogView";
import { FriendsFeedView } from "@/views/FriendsFeedView";
import { ChatsView } from "@/views/ChatsView";
import { ProfileView } from "@/views/ProfileView";
import { MovieDetailModal } from "@/components/movies/MovieDetailModal";

export default function Home() {
  const [currentUser, setCurrentUser] = useState<User>(api.getCurrentUser());
  const [activeTab, setActiveTab] = useState<"catalog" | "feed" | "chats" | "profile">("catalog");
  const [selectedMovie, setSelectedMovie] = useState<Movie | null>(null);
  const [chatTargetFriend, setChatTargetFriend] = useState<Friend | null>(null);
  const [dbStatus, setDbStatus] = useState<{ online: boolean; database?: string }>({ online: true, database: "Neon DB (PostgreSQL Cloud)" });

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
      />

      {/* Main Content Area */}
      <main className="flex-grow">
        {activeTab === "catalog" && (
          <CatalogView
            currentUser={currentUser}
            onSelectMovie={(movie) => setSelectedMovie(movie)}
          />
        )}

        {activeTab === "feed" && (
          <FriendsFeedView
            currentUser={currentUser}
            onSelectMovieById={handleSelectMovieById}
            onOpenChatWithFriend={handleOpenChatWithFriend}
          />
        )}

        {activeTab === "chats" && (
          <ChatsView
            currentUser={currentUser}
            onSelectMovieById={handleSelectMovieById}
            initialFriendForChat={chatTargetFriend}
          />
        )}

        {activeTab === "profile" && (
          <ProfileView
            currentUser={currentUser}
            onUpdateUser={setCurrentUser}
            onSelectMovieById={handleSelectMovieById}
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
      />
    </div>
  );
}

