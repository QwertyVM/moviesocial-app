"use server";

import prisma from "@/lib/prisma";
import { User, UserLocation } from "@/types";
import { AVAILABLE_CITIES } from "@/data/curatedMovies";

function formatDbUser(dbUser: any): User {
  const loc: UserLocation = AVAILABLE_CITIES.find(
    (c) => c.city.toLowerCase() === (dbUser.city || "").toLowerCase()
  ) || {
    city: dbUser.city || "Lima",
    country: dbUser.country || "Perú",
    countryCode: dbUser.countryCode || "PE",
    flagEmoji: "🇵🇪",
    isLocal: true,
  };

  return {
    id: dbUser.id,
    email: dbUser.email || "",
    displayName: dbUser.displayName,
    username: dbUser.username,
    bio: dbUser.bio || "",
    avatarUrl:
      dbUser.avatarUrl ||
      `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(dbUser.username)}`,
    isPremium: dbUser.isPremium ?? false,
    subscriptionPlan: dbUser.isPremium ? "global_monthly" : "base",
    subscriptionPrice: "S/ 14.90 / mes",
    location: loc,
    createdAt: dbUser.createdAt ? dbUser.createdAt.toISOString() : undefined,
  };
}

export async function getUserById(userId: string): Promise<User | null> {
  try {
    const dbUser = await prisma.user.findUnique({
      where: { id: userId },
    });
    if (dbUser) return formatDbUser(dbUser);
  } catch (err) {
    console.warn("Neon DB getUserById error:", err);
  }
  return null;
}

export async function loginOrRegisterUser(data: {
  displayName: string;
  username: string;
  email: string;
  city?: string;
  country?: string;
  countryCode?: string;
  bio?: string;
  avatarUrl?: string;
}): Promise<User> {
  const rawUsername = data.username.trim();
  const cleanUsername = rawUsername.startsWith("@") ? rawUsername : `@${rawUsername}`;
  const cleanEmail = (data.email || "").trim().toLowerCase();

  try {
    // Buscar usuario existente por email o username
    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          cleanEmail ? { email: cleanEmail } : { username: cleanUsername },
          { username: cleanUsername },
        ],
      },
    });

    if (existing) {
      const updated = await prisma.user.update({
        where: { id: existing.id },
        data: {
          displayName: data.displayName || existing.displayName,
          city: data.city || existing.city,
          country: data.country || existing.country,
          countryCode: data.countryCode || existing.countryCode,
          avatarUrl: data.avatarUrl || existing.avatarUrl,
        },
      });
      return formatDbUser(updated);
    }

    // Crear nuevo usuario real en Neon DB
    const newId = `user_${Date.now()}`;
    const created = await prisma.user.create({
      data: {
        id: newId,
        email: cleanEmail,
        displayName: data.displayName || cleanUsername.replace("@", ""),
        username: cleanUsername,
        bio: data.bio || "Cinéfilo en MovieSocial",
        avatarUrl:
          data.avatarUrl ||
          `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanUsername)}`,
        city: data.city || "Lima",
        country: data.country || "Perú",
        countryCode: data.countryCode || "PE",
        isPremium: false,
      },
    });

    return formatDbUser(created);
  } catch (err) {
    console.warn("Neon DB loginOrRegisterUser fallback:", err);
    return {
      id: `user_${Date.now()}`,
      email: cleanEmail,
      displayName: data.displayName || cleanUsername.replace("@", ""),
      username: cleanUsername,
      bio: data.bio || "Cinéfilo en MovieSocial",
      avatarUrl:
        data.avatarUrl ||
        `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanUsername)}`,
      isPremium: false,
      subscriptionPlan: "base",
      subscriptionPrice: "S/ 14.90 / mes",
      location: {
        city: data.city || "Lima",
        country: data.country || "Perú",
        countryCode: data.countryCode || "PE",
        flagEmoji: "🇵🇪",
        isLocal: true,
      },
    };
  }
}

export async function updateUserAction(data: {
  id: string;
  displayName?: string;
  username?: string;
  bio?: string;
  city?: string;
  country?: string;
  countryCode?: string;
  avatarUrl?: string;
  isPremium?: boolean;
}): Promise<User | null> {
  try {
    const updated = await prisma.user.update({
      where: { id: data.id },
      data: {
        displayName: data.displayName,
        username: data.username,
        bio: data.bio,
        city: data.city,
        country: data.country,
        countryCode: data.countryCode,
        avatarUrl: data.avatarUrl,
        isPremium: data.isPremium,
      },
    });
    return formatDbUser(updated);
  } catch (err) {
    console.warn("Neon DB updateUserAction error:", err);
  }
  return null;
}
