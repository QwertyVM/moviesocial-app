"use server";

import prisma from "@/lib/prisma";
import { Friend } from "@/types";
import { INITIAL_FRIENDS } from "@/data/curatedMovies";

export async function getFriends(): Promise<Friend[]> {
  try {
    const dbFriends = await prisma.friend.findMany({
      orderBy: { displayName: "asc" },
    });

    if (dbFriends.length > 0) {
      return dbFriends.map((f) => ({
        id: f.id,
        displayName: f.displayName,
        username: f.username,
        avatarUrl: f.avatarUrl || "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200",
        isMutual: f.isMutual,
        mutualMoviesCount: f.mutualMoviesCount,
      }));
    }
  } catch (err) {
    console.warn("Neon DB getFriends fallback:", err);
  }

  return INITIAL_FRIENDS;
}

export async function addFriend(username: string): Promise<Friend> {
  const cleanUser = username.trim().startsWith("@") ? username.trim() : `@${username.trim()}`;
  const friendId = `friend_${Date.now()}`;
  const newFriend: Friend = {
    id: friendId,
    displayName: cleanUser.replace("@", ""),
    username: cleanUser,
    avatarUrl: `https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200`,
    isMutual: true,
    mutualMoviesCount: 1,
  };

  try {
    await prisma.friend.create({
      data: {
        id: newFriend.id,
        displayName: newFriend.displayName,
        username: newFriend.username,
        avatarUrl: newFriend.avatarUrl,
        isMutual: true,
        mutualMoviesCount: 1,
      },
    });
  } catch (err) {
    console.warn("Neon DB addFriend fallback:", err);
  }

  return newFriend;
}

