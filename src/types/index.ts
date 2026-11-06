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

export interface MovieCastMember {
  id: number;
  name: string;
  character?: string;
  profileURL?: string;
}

export interface MovieTrailerInfo {
  key: string;
  name: string;
  language: 'es' | 'en' | 'other';
  languageLabel: string;
  youtubeUrl: string;
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
  originCountry?: string;
  originCountryName?: string;
  ratings: ExternalRatings;
  isInTheatersLocally?: boolean;
  theatersPlaying?: string[];
  showtimes?: CinemaShowtime[];
  theatricalCountries?: string[];
  trailer?: MovieTrailerInfo;
  cast?: MovieCastMember[];
  productionCompany?: string; // Casa productora o Distribuidora (ej: A24, Warner Bros.)
  revenueUSD?: number; // Taquilla mundial en dólares
  boxOfficeFormatted?: string; // ej: "$124.5M USD"
  budgetFormatted?: string;
}

export interface UserMovieStatus {
  inWatchlist: boolean;
  isWatched: boolean;
  isFavorite: boolean;
  friendsInterested: Array<{
    id: string;
    displayName: string;
    avatarUrl?: string;
  }>;
  friendsInterestedCount: number;
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
 * Fórmula para el cruce ponderado del Rating Oficial (Consenso Externo de la Industria):
 * - Si aún no hay reseñas de la comunidad insertadas, el ponderado se calcula dinámicamente entre las fuentes disponibles:
 *     - IMDb (50%)
 *     - Rotten Tomatoes Críticos (30%)
 *     - Rotten Tomatoes Audiencia (20%)
 * - Si alguna de las fuentes externas no tiene datos, el algoritmo redistribuye el 100% del peso únicamente entre las disponibles.
 * - Si la comunidad de MovieSocial ya tiene reseñas insertadas, se incorpora automáticamente con un peso del 35%.
 * Normalizado a base 10 con un decimal.
 */
export function calculateCompositeScore(
  ratings: ExternalRatings,
  communityAvg?: number
): number {
  let totalWeight = 0;
  let weightedSum = 0;

  // 1. Reseñas internas de MovieSocial (si existen)
  if (communityAvg != null && communityAvg > 0) {
    weightedSum += (communityAvg * 20) * 0.35;
    totalWeight += 0.35;
  }

  // 2. Fuentes externas (ponderadas dinámicamente)
  if (ratings.imdbScore != null && ratings.imdbScore > 0) {
    const w = totalWeight > 0 ? 0.35 : 0.50;
    weightedSum += (ratings.imdbScore * 10) * w;
    totalWeight += w;
  }
  if (ratings.rottenTomatoesCritics != null && ratings.rottenTomatoesCritics > 0) {
    const w = totalWeight > 0 ? 0.15 : 0.30;
    weightedSum += ratings.rottenTomatoesCritics * w;
    totalWeight += w;
  }
  if (ratings.rottenTomatoesAudience != null && ratings.rottenTomatoesAudience > 0) {
    const w = totalWeight > 0 ? 0.15 : 0.20;
    weightedSum += ratings.rottenTomatoesAudience * w;
    totalWeight += w;
  }

  if (totalWeight === 0) return 0;
  const scoreBase100 = weightedSum / totalWeight;
  return Number((scoreBase100 / 10.0).toFixed(1));
}

