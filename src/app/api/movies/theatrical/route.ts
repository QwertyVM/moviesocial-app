import { NextRequest, NextResponse } from "next/server";
import { getTheatricalMovies } from "@/actions/movies";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const country = searchParams.get("country") || "PE";

    const movies = await getTheatricalMovies(country);

    return NextResponse.json({
      movies,
      count: movies.length,
      country,
      source: "cloud_service",
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error?.message || "Error al obtener estrenos en cartelera" },
      { status: 500 }
    );
  }
}
