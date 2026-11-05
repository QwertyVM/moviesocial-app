export interface ExternalRatings {
  rottenTomatoesCritics?: number | null; // 0-100% Tomatometer
  rottenTomatoesAudience?: number | null; // 0-100% Popcorn
  imdbScore?: number | null; // 1.0 - 10.0
  imdbVotes?: string | null; // e.g. "1.2M", "450K"
  compositeScore?: number | null; // 1.0 - 10.0
}

export interface CinemaShowtime {
  cinemaName: string;
  city: string;
  roomFormat: string;
  times: string[];
}

export interface Movie {
  id: string;
  title: string;
  overview: string;
  releaseYear: number;
  releaseDate: string;
  posterURL: string;
  backdropURL?: string;
  genres: string[];
  runtimeMinutes: number;
  imdbId?: string;
  director?: string;
  countryOfOrigin?: string;
  originCountryName?: string;
  ratings: ExternalRatings;
  isInTheatersLocally?: boolean;
  theatersPlaying?: string[];
  showtimes?: CinemaShowtime[];
  theatricalCountries?: string[];
}

export interface UserLocation {
  city: string;
  country: string;
  countryCode: string;
  flagEmoji: string;
  isLocal: boolean;
  area?: string;
}

export interface User {
  id: string;
  email: string;
  displayName: string;
  username: string;
  bio: string;
  avatarUrl: string;
  isPremium: boolean; // true = Suscripción Mensual Activa (Comunidad Global y Mundo), false = Plan Base (Solo Amigos)
  subscriptionPlan?: 'base' | 'global_monthly';
  subscriptionPrice?: string; // e.g. "S/ 14.90 / mes"
  subscriptionRenewalDate?: string;
  location: UserLocation;
  createdAt?: string;
}

export interface ReviewComment {
  id: string;
  reviewId: string;
  userId: string;
  userName: string;
  userAvatarUrl?: string;
  userIsPremium?: boolean;
  text: string;
  createdAt: string;
}

export interface Review {
  id: string;
  movieId: string;
  movieTitle: string;
  moviePosterUrl?: string;
  movieReleaseYear?: number;
  userId: string;
  userName: string;
  userAvatarUrl?: string;
  userIsPremium?: boolean;
  rating: number; // 1.0 to 5.0
  comment: string;
  likesCount: number;
  helpfulCount: number;
  isCommunity: boolean; // true = visible para el mundo / comunidad (requiere suscripción mensual), false = solo amigos (plan base)
  createdAt: string;
  comments?: ReviewComment[];
  isLikedByMe?: boolean;
}

export interface Friend {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string;
  isMutual: boolean;
  mutualMoviesCount: number;
  bio?: string;
}

export interface MovieGroup {
  id: string;
  name: string;
  description: string;
  iconEmoji: string;
  creatorId: string;
  creatorName: string;
  inviteCode: string;
  messagesCount: number;
  membersCount?: number;
  createdAt: string;
}

export interface ChatMessage {
  id: string;
  conversationId?: string;
  groupId?: string;
  senderId: string;
  senderName: string;
  senderAvatarUrl?: string;
  text: string;
  messageType: 'text' | 'movie';
  sharedMovieId?: string;
  sharedMovieTitle?: string;
  sharedMoviePosterUrl?: string;
  sharedMovieScore?: number;
  createdAt: string;
}

export interface DirectConversation {
  id: string;
  participant: Friend;
  lastMessage?: ChatMessage;
  unreadCount: number;
  updatedAt: string;
}

/**
 * Fórmula oficial de MovieSocial para el cruce ponderado de calificaciones (MovieScore):
 * - 50% IMDb (escala 0-100)
 * - 30% Rotten Tomatoes Críticos (Tomatometer)
 * - 20% Rotten Tomatoes Audiencia (Popcornmeter)
 * Normalizado a base 10 con un decimal.
 */
export function calculateCompositeScore(ratings: ExternalRatings): number {
  if (ratings.compositeScore && ratings.compositeScore > 0) {
    return Number(ratings.compositeScore.toFixed(1));
  }

  let totalWeight = 0;
  let weightedSum = 0;

  if (ratings.imdbScore != null && ratings.imdbScore > 0) {
    weightedSum += ratings.imdbScore * 10 * 0.50;
    totalWeight += 0.50;
  }
  if (ratings.rottenTomatoesCritics != null && ratings.rottenTomatoesCritics > 0) {
    weightedSum += ratings.rottenTomatoesCritics * 0.30;
    totalWeight += 0.30;
  }
  if (ratings.rottenTomatoesAudience != null && ratings.rottenTomatoesAudience > 0) {
    weightedSum += ratings.rottenTomatoesAudience * 0.20;
    totalWeight += 0.20;
  }

  if (totalWeight === 0) return 7.5;
  const scoreBase100 = weightedSum / totalWeight;
  return Number((scoreBase100 / 10.0).toFixed(1));
}

