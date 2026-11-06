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
  } catch (err) {
    console.warn("Neon DB reviews fallback:", err);
    return [];
  }
}

export async function getMovieReviewStats(movieId: string): Promise<{
  totalReviews: number;
  friendsAverage: number | null;
  friendsCount: number;
  communityAverage: number | null;
  communityCount: number;
  distribution: Record<number, number>;
}> {
  try {
    const allReviews = await getReviews(movieId);
    let friendsSum = 0;
    let friendsCount = 0;
    let communitySum = 0;
    let communityCount = 0;
    const distribution: Record<number, number> = {
      1: 0, 2: 0, 3: 0, 4: 0, 5: 0
    };

    for (const r of allReviews) {
      const roundedStar = Math.min(5, Math.max(1, Math.round(r.rating)));
      distribution[roundedStar] = (distribution[roundedStar] || 0) + 1;

      if (r.isCommunity) {
        communitySum += r.rating;
        communityCount++;
      } else {
        friendsSum += r.rating;
        friendsCount++;
      }
    }

    return {
      totalReviews: allReviews.length,
      friendsAverage: friendsCount > 0 ? Number((friendsSum / friendsCount).toFixed(1)) : null,
      friendsCount,
      communityAverage: communityCount > 0 ? Number((communitySum / communityCount).toFixed(1)) : null,
      communityCount,
      distribution,
    };
  } catch (err) {
    console.warn("Error calculating review stats:", err);
    return {
      totalReviews: 0,
      friendsAverage: null,
      friendsCount: 0,
      communityAverage: null,
      communityCount: 0,
      distribution: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
    };
  }
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

