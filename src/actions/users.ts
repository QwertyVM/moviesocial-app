"use server";

import prisma from "@/lib/prisma";
import { User } from "@/types";
import { DEFAULT_USER, AVAILABLE_CITIES } from "@/data/curatedMovies";

export async function getUser(userId: string = "user_alex_101"): Promise<User> {
  try {
    const dbUser = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (dbUser) {
      const loc = AVAILABLE_CITIES.find((c) => c.city.toLowerCase() === (dbUser.city || "").toLowerCase()) || {
        city: dbUser.city || "Lima",
        country: dbUser.country || "Perú",
        countryCode: dbUser.countryCode || "PE",
        flagEmoji: "🇵🇪",
        isLocal: true,
      };

      return {
        id: dbUser.id,
        email: dbUser.email || "cinefilo@apple.com",
        displayName: dbUser.displayName,
        username: dbUser.username,
        bio: dbUser.bio || "",
        avatarUrl: dbUser.avatarUrl || "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200",
        isPremium: dbUser.isPremium,
        location: loc,
        createdAt: dbUser.createdAt ? dbUser.createdAt.toISOString() : undefined,
      };
    }
  } catch (err) {
    console.warn("Neon DB getUser fallback:", err);
  }

  return DEFAULT_USER;
}

