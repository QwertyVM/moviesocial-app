import { NextRequest, NextResponse } from "next/server";
import { getCatalogMovies } from "@/actions/movies";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const countryCode = searchParams.get("country") || "PE";
    const decade = searchParams.get("decade") || "all";
    const rawGenre = searchParams.get("genre") || "all";
    const genre = rawGenre.toLowerCase() === "todos" ? "all" : rawGenre;
    const sortBy = (searchParams.get("sortBy") as any) || "ratingDesc";
    const searchQuery =
      searchParams.get("q") ||
      searchParams.get("searchQuery") ||
      searchParams.get("search") ||
      "";
    const minRatingParam = searchParams.get("minRating");
    const minRating = minRatingParam ? parseFloat(minRatingParam) : null;
    const page = parseInt(searchParams.get("page") || "1", 10);

    const movies = await getCatalogMovies({
      countryCode,
      decade,
      genre,
      sortBy,
      searchQuery,
      minRating,
      page,
    });

    return NextResponse.json({
      movies,
      count: movies.length,
      filters: { countryCode, decade, genre, sortBy, searchQuery, minRating },
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error?.message || "Error al obtener catálogo de películas" },
      { status: 500 }
    );
  }
}
