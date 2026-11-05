"use server";

import prisma from "@/lib/prisma";
import { Friend } from "@/types";

export async function getFriends(): Promise<Friend[]> {
  try {
    const dbFriends = await prisma.friend.findMany({
      orderBy: { displayName: "asc" },
    });

    return dbFriends.map((f) => ({
      id: f.id,
      displayName: f.displayName,
      username: f.username,
      avatarUrl:
        f.avatarUrl ||
        `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(f.username)}`,
      isMutual: f.isMutual,
      mutualMoviesCount: f.mutualMoviesCount,
    }));
  } catch (err) {
    console.warn("Neon DB getFriends fallback:", err);
    return [];
  }
}

export async function addFriend(username: string): Promise<Friend> {
  const cleanUser = username.trim().startsWith("@") ? username.trim() : `@${username.trim()}`;
  const friendId = `friend_${Date.now()}`;
  const newFriend: Friend = {
    id: friendId,
    displayName: cleanUser.replace("@", ""),
    username: cleanUser,
    avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanUser)}`,
    isMutual: true,
    mutualMoviesCount: 0,
  };

  try {
    await prisma.friend.create({
      data: {
        id: newFriend.id,
        displayName: newFriend.displayName,
        username: newFriend.username,
        avatarUrl: newFriend.avatarUrl,
        isMutual: true,
        mutualMoviesCount: 0,
      },
    });
  } catch (err) {
    console.warn("Neon DB addFriend fallback:", err);
  }

  return newFriend;
}
