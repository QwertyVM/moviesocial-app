import { NextResponse } from "next/server";

export async function GET() {
  const hasTmdb = Boolean(process.env.TMDB_API_KEY);
  return NextResponse.json({
    status: "online",
    server: "MovieSocial App Web API (Next.js 15)",
    version: "2.5.0",
    movieProvider: hasTmdb ? "The Movie Database (TMDB Live API)" : "Curated Fallback",
    database: "Neon DB (PostgreSQL Serverless)",
    timestamp: new Date().toISOString(),
  });
}
