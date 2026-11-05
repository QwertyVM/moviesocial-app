"use server";

import prisma from "@/lib/prisma";
import { CURATED_MOVIES, CITY_SHOWTIMES } from "@/data/curatedMovies";
import { Movie, CinemaShowtime } from "@/types";

export async function getTheatricalMovies(city: string = "Lima"): Promise<Movie[]> {
  try {
    const dbMovies = await prisma.theatricalMovie.findMany({
      where: { isActive: true },
      include: { showtimes: true },
      orderBy: { releaseDate: "desc" },
    });

    if (dbMovies.length > 0) {
      const normCity = city.trim().toLowerCase();
      return dbMovies.map((m) => {
        const localShowtimes: CinemaShowtime[] = m.showtimes
          .filter((s) => s.city.toLowerCase() === normCity)
          .map((s) => ({
            cinemaName: s.cinemaName,
            city: s.city,
            roomFormat: s.roomFormat,
            times: s.times || [],
          }));

        return {
          id: m.id,
          title: m.title,
          overview: m.synopsis || "",
          releaseYear: m.releaseDate ? new Date(m.releaseDate).getFullYear() : 2026,
          releaseDate: m.releaseDate ? m.releaseDate.toISOString().split("T")[0] : "2026-10-25",
          posterURL: m.posterUrl || "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500",
          genres: m.genres ? m.genres.split(",") : ["Drama"],
          runtimeMinutes: 110,
          director: m.director || undefined,
          countryOfOrigin: m.originCountry || "US",
          originCountryName: m.originCountryName || undefined,
          ratings: {
            compositeScore: m.compositeScore ? Number(m.compositeScore) : 8.0,
            imdbScore: 8.2,
            rottenTomatoesCritics: 88,
            rottenTomatoesAudience: 90,
          },
          isInTheatersLocally: localShowtimes.length > 0,
          theatersPlaying: localShowtimes.map((s) => s.cinemaName),
          showtimes: localShowtimes,
        };
      });
    }
  } catch (err) {
    console.warn("Neon DB query fallback to curated catalog:", err);
  }

  // Fallback a catálogo curado offline
  const normCity = city.trim().toLowerCase();
  const cityData = CITY_SHOWTIMES[normCity] || {};

  return CURATED_MOVIES.filter((m) => m.releaseYear >= 2024 || (cityData[m.id] && cityData[m.id].length > 0)).map(
    (m) => {
      const showtimes = cityData[m.id] || [];
      return {
        ...m,
        isInTheatersLocally: showtimes.length > 0,
        theatersPlaying: showtimes.map((s) => s.cinemaName),
        showtimes,
      };
    }
  );
}

export async function getClassicsMovies(decade: string = "all"): Promise<Movie[]> {
  let list = CURATED_MOVIES.filter((m) => m.releaseYear < 2024);

  if (decade !== "all") {
    list = list.filter((m) => {
      const y = m.releaseYear;
      if (decade === "60s") return y <= 1969;
      if (decade === "70s") return y >= 1970 && y <= 1979;
      if (decade === "80s") return y >= 1980 && y <= 1989;
      if (decade === "90s") return y >= 1990 && y <= 1999;
      if (decade === "2000s") return y >= 2000 && y <= 2009;
      if (decade === "2010s") return y >= 2010 && y <= 2019;
      return true;
    });
  }

  return list.sort((a, b) => (b.ratings.compositeScore || 0) - (a.ratings.compositeScore || 0));
}

