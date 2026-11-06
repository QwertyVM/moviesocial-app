import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const mode = searchParams.get("mode") || "all";

    const dbFriends = await prisma.friend.findMany({
      orderBy: { displayName: "asc" },
    });

    const friends = dbFriends.map((f) => ({
      id: f.id,
      displayName: f.displayName,
      username: f.username,
      avatarUrl:
        f.avatarUrl ||
        `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(f.username)}`,
      isMutual: f.isMutual,
      mutualMoviesCount: f.mutualMoviesCount,
      isFriend: true,
    }));

    if (mode === "friends") {
      return NextResponse.json({ friends });
    }

    // Traer también usuarios registrados de la comunidad (para poder interactuar o descubrirlos)
    const dbUsers = await prisma.user.findMany({
      take: 20,
      orderBy: { createdAt: "desc" },
    });

    const friendUsernames = new Set(friends.map((f) => f.username.toLowerCase()));

    const communityUsers = dbUsers
      .filter((u) => !friendUsernames.has(u.username.toLowerCase()))
      .map((u) => ({
        id: u.id,
        displayName: u.displayName,
        username: u.username,
        avatarUrl:
          u.avatarUrl ||
          `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(u.username)}`,
        isMutual: false,
        mutualMoviesCount: 0,
        isFriend: false,
        isPremium: u.isPremium,
      }));

    return NextResponse.json({
      friends,
      community: communityUsers,
      totalFriends: friends.length,
      totalCommunity: communityUsers.length,
    });
  } catch (error: any) {
    console.error("GET /api/friends error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al obtener lista de amigos y comunidad" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { username } = body;

    if (!username) {
      return NextResponse.json(
        { error: "El nombre de usuario es requerido" },
        { status: 400 }
      );
    }

    const cleanUser = username.trim().startsWith("@") ? username.trim() : `@${username.trim()}`;
    const friendId = `friend_${Date.now()}`;

    const created = await prisma.friend.create({
      data: {
        id: friendId,
        displayName: cleanUser.replace("@", ""),
        username: cleanUser,
        avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(cleanUser)}`,
        isMutual: true,
        mutualMoviesCount: 0,
      },
    });

    return NextResponse.json({
      friend: {
        id: created.id,
        displayName: created.displayName,
        username: created.username,
        avatarUrl: created.avatarUrl,
        isMutual: created.isMutual,
        mutualMoviesCount: created.mutualMoviesCount,
        isFriend: true,
      },
    });
  } catch (error: any) {
    console.error("POST /api/friends error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al agregar amigo" },
      { status: 500 }
    );
  }
}
