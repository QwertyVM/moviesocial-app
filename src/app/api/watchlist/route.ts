import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";

// Garantizar que la tabla exista en Neon DB
async function ensureWatchlistTable() {
  try {
    await prisma.$executeRawUnsafe(`
      CREATE TABLE IF NOT EXISTS user_watchlists (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        movie_id TEXT NOT NULL,
        movie_title TEXT NOT NULL,
        movie_poster_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, movie_id)
      );
    `);
  } catch (err) {
    console.warn("Table ensureWatchlistTable notice:", err);
  }
}

export async function GET(request: NextRequest) {
  try {
    await ensureWatchlistTable();
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId");

    if (!userId) {
      return NextResponse.json({ watchlist: [], movieIds: [] });
    }

    const rows: any[] = await prisma.$queryRawUnsafe(
      `SELECT * FROM user_watchlists WHERE user_id = $1 ORDER BY created_at DESC`,
      userId
    );

    const movieIds = rows.map((r) => r.movie_id);

    return NextResponse.json({
      watchlist: rows.map((r) => ({
        id: r.id,
        userId: r.user_id,
        movieId: r.movie_id,
        movieTitle: r.movie_title,
        moviePosterUrl: r.movie_poster_url,
        createdAt: r.created_at,
      })),
      movieIds,
      count: rows.length,
    });
  } catch (error: any) {
    console.error("GET /api/watchlist error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al obtener watchlist" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    await ensureWatchlistTable();
    const body = await request.json();
    const { userId, movieId, movieTitle, moviePosterUrl } = body;

    if (!userId || !movieId) {
      return NextResponse.json(
        { error: "userId y movieId son obligatorios" },
        { status: 400 }
      );
    }

    // Verificar si ya está en la watchlist para togglear
    const existing: any[] = await prisma.$queryRawUnsafe(
      `SELECT id FROM user_watchlists WHERE user_id = $1 AND movie_id = $2 LIMIT 1`,
      userId,
      movieId
    );

    let inWatchlist = false;

    if (existing && existing.length > 0) {
      // Remover
      await prisma.$executeRawUnsafe(
        `DELETE FROM user_watchlists WHERE user_id = $1 AND movie_id = $2`,
        userId,
        movieId
      );
      inWatchlist = false;
    } else {
      // Agregar
      const id = `wl_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
      await prisma.$executeRawUnsafe(
        `INSERT INTO user_watchlists (id, user_id, movie_id, movie_title, movie_poster_url)
         VALUES ($1, $2, $3, $4, $5)`,
        id,
        userId,
        movieId,
        movieTitle || "Película",
        moviePosterUrl || null
      );
      inWatchlist = true;
    }

    // Obtener todos los IDs actualizados del usuario
    const rows: any[] = await prisma.$queryRawUnsafe(
      `SELECT movie_id FROM user_watchlists WHERE user_id = $1`,
      userId
    );
    const movieIds = rows.map((r) => r.movie_id);

    return NextResponse.json({
      inWatchlist,
      movieIds,
      count: movieIds.length,
    });
  } catch (error: any) {
    console.error("POST /api/watchlist error:", error);
    return NextResponse.json(
      { error: error?.message || "Error al actualizar watchlist" },
      { status: 500 }
    );
  }
}
