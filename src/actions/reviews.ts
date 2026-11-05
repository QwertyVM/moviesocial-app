"use server";

import prisma from "@/lib/prisma";
import { Review } from "@/types";
import { INITIAL_REVIEWS } from "@/data/curatedMovies";

export async function getReviews(movieId?: string): Promise<Review[]> {
  try {
    const where = movieId ? { movieId } : {};
    const dbReviews = await prisma.review.findMany({
      where,
      include: { comments: true },
      orderBy: { createdAt: "desc" },
    });

    if (dbReviews.length > 0) {
      return dbReviews.map((r) => ({
        id: r.id,
        movieId: r.movieId,
        movieTitle: r.movieTitle,
        moviePosterUrl: r.moviePosterUrl || undefined,
        movieReleaseYear: r.movieReleaseYear || undefined,
        userId: r.userId,
        userName: r.userName,
        userAvatarUrl: r.userAvatarUrl || undefined,
        rating: Number(r.rating),
        comment: r.comment || "",
        likesCount: r.likesCount,
        helpfulCount: r.helpfulCount,
        isCommunity: r.isCommunity,
        createdAt: r.createdAt ? r.createdAt.toISOString() : new Date().toISOString(),
        comments: r.comments.map((c) => ({
          id: c.id,
          reviewId: c.reviewId,
          userId: c.userId,
          userName: c.userName,
          userAvatarUrl: c.userAvatarUrl || undefined,
          text: c.text,
          createdAt: c.createdAt ? c.createdAt.toISOString() : new Date().toISOString(),
        })),
      }));
    }
  } catch (err) {
    console.warn("Neon DB reviews fallback:", err);
  }

  let list = [...INITIAL_REVIEWS];
  if (movieId) {
    list = list.filter((r) => r.movieId === movieId);
  }
  return list;
}

export async function submitReview(data: {
  movieId: string;
  movieTitle: string;
  moviePosterUrl?: string;
  movieReleaseYear?: number;
  userId: string;
  userName: string;
  userAvatarUrl?: string;
  rating: number;
  comment: string;
  isCommunity?: boolean;
}): Promise<Review> {
  const revId = `rev_${Date.now()}`;
  try {
    const created = await prisma.review.create({
      data: {
        id: revId,
        movieId: data.movieId,
        movieTitle: data.movieTitle,
        moviePosterUrl: data.moviePosterUrl,
        movieReleaseYear: data.movieReleaseYear,
        userId: data.userId,
        userName: data.userName,
        userAvatarUrl: data.userAvatarUrl,
        rating: data.rating,
        comment: data.comment,
        isCommunity: !!data.isCommunity,
      },
    });

    return {
      id: created.id,
      movieId: created.movieId,
      movieTitle: created.movieTitle,
      moviePosterUrl: created.moviePosterUrl || undefined,
      movieReleaseYear: created.movieReleaseYear || undefined,
      userId: created.userId,
      userName: created.userName,
      userAvatarUrl: created.userAvatarUrl || undefined,
      rating: Number(created.rating),
      comment: created.comment || "",
      likesCount: created.likesCount,
      helpfulCount: created.helpfulCount,
      isCommunity: created.isCommunity,
      createdAt: created.createdAt ? created.createdAt.toISOString() : new Date().toISOString(),
      comments: [],
    };
  } catch (err) {
    console.warn("Neon DB create review fallback:", err);
    return {
      id: revId,
      movieId: data.movieId,
      movieTitle: data.movieTitle,
      moviePosterUrl: data.moviePosterUrl,
      movieReleaseYear: data.movieReleaseYear,
      userId: data.userId,
      userName: data.userName,
      userAvatarUrl: data.userAvatarUrl,
      rating: data.rating,
      comment: data.comment,
      likesCount: 0,
      helpfulCount: 0,
      isCommunity: !!data.isCommunity,
      createdAt: new Date().toISOString(),
      comments: [],
    };
  }
}

