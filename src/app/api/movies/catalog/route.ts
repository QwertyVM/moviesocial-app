import { NextRequest, NextResponse } from "next/server";
import { getCatalogMovies } from "@/actions/movies";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const countryCode = searchParams.get("country") || "PE";
    const decade = searchParams.get("decade") || "all";
    const genre = searchParams.get("genre") || "all";
    const sortBy = (searchParams.get("sortBy") as any) || "yearDesc";
    const searchQuery = searchParams.get("q") || searchParams.get("searchQuery") || "";
    const minRatingParam = searchParams.get("minRating");
    const minRating = minRatingParam ? parseFloat(minRatingParam) : null;

    const movies = await getCatalogMovies({
      countryCode,
      decade,
      genre,
      sortBy,
      searchQuery,
      minRating,
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
