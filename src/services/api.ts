import {
  Movie,
  Review,
  Friend,
  MovieGroup,
  ChatMessage,
  DirectConversation,
  User,
  CinemaShowtime,
  UserLocation,
} from '../types';
import {
  CURATED_MOVIES,
  CITY_SHOWTIMES,
  AVAILABLE_CITIES,
} from '../data/curatedMovies';
import { getTheatricalMovies, getCatalogMovies, getMovieByIdAction, getCinephileSpotlight, CinephileSpotlightData } from '@/actions/movies';
import { getMovieReviewStats, getReviews as getDbReviews, submitReview as submitDbReview } from '@/actions/reviews';
import { getFriends as getDbFriends, addFriend as addDbFriend } from '@/actions/friends';
import { getGroups as getDbGroups, createGroup as createDbGroup } from '@/actions/chats';

const API_BASE = '/api';

// Helper de almacenamiento local para persistencia inmediata en el navegador
function getLocalItem<T>(key: string, fallback: T): T {
  try {
    const val = localStorage.getItem(`moviesocial_${key}`);
    return val ? JSON.parse(val) : fallback;
  } catch {
    return fallback;
  }
}

function setLocalItem<T>(key: string, val: T): void {
  try {
    localStorage.setItem(`moviesocial_${key}`, JSON.stringify(val));
  } catch (err) {
    console.warn('LocalStorage error:', err);
  }
}

class MovieSocialAPI {
  private user: User | null;
  private friends: Friend[];
  private reviews: Review[];
  private groups: MovieGroup[];
  private groupMessages: Record<string, ChatMessage[]>;
  private directConversations: DirectConversation[];
  private directMessages: Record<string, ChatMessage[]>;

  constructor() {
    const storedUser = getLocalItem<User | null>('user', null);
    // Purgar mock heredado si existe para asegurar datos reales
    if (storedUser && (storedUser.id === 'user_alex_101' || storedUser.username === '@alex_rivera')) {
      this.user = null;
      try {
        localStorage.removeItem('moviesocial_user');
      } catch {}
    } else {
      this.user = storedUser;
    }

    const storedFriends = getLocalItem<Friend[]>('friends', []);
    this.friends = storedFriends.filter(
      (f) => !f.id.startsWith('friend_valeria') && !f.id.startsWith('friend_lucas')
    );

    const storedReviews = getLocalItem<Review[]>('reviews', []);
    this.reviews = storedReviews.filter(
      (r) => !['rev_01', 'rev_02', 'rev_03', 'rev_04'].includes(r.id)
    );

    const storedGroups = getLocalItem<MovieGroup[]>('groups', []);
    this.groups = storedGroups.filter(
      (g) => !['grp_cine_peruano', 'grp_nolan_fans'].includes(g.id)
    );

    this.groupMessages = getLocalItem<Record<string, ChatMessage[]>>('group_messages', {});
    this.directConversations = getLocalItem<DirectConversation[]>('direct_convos', []);
    this.directMessages = getLocalItem<Record<string, ChatMessage[]>>('direct_messages', {});
  }

  // --- Backend Check ---
  async checkBackendStatus(): Promise<{ online: boolean; database?: string }> {
    try {
      const res = await fetch(`${API_BASE}/health`, { signal: AbortSignal.timeout(2000) });
      if (res.ok) {
        const data = await res.json();
        return { online: true, database: data.database };
      }
    } catch {
      // Backend offline o sin proxy activo
    }
    return { online: false };
  }

  // --- Películas y Cartelera ---
  async getMovies(options?: {
    category?: 'nowPlaying' | 'classics' | 'catalog';
    city?: string;
    countryCode?: string;
    decade?: string;
    minRating?: number | null;
    genre?: string;
    sortBy?: 'yearDesc' | 'ratingDesc' | 'criticsDesc' | 'audienceDesc';
    searchQuery?: string;
  }): Promise<Movie[]> {
    const {
      category = 'nowPlaying',
      city = this.user?.location.city || 'Lima',
      countryCode = this.user?.location.countryCode || 'PE',
      decade = 'all',
      minRating = null,
      genre = 'all',
      sortBy = category === 'nowPlaying' ? 'ratingDesc' : 'yearDesc',
      searchQuery = '',
    } = options || {};

    let list = [...CURATED_MOVIES];

    // Marcar si la película está en estreno en cines según el país de la ubicación
    list = list.map((m) => {
      const isTheatrical = Boolean(
        m.theatricalCountries && m.theatricalCountries.includes(countryCode)
      );
      return {
        ...m,
        isInTheatersLocally: isTheatrical,
        theatersPlaying: isTheatrical ? ['Cines comerciales en ' + (this.user?.location.country || city)] : [],
      };
    });

    // Filtro por Cartelera (Estrenos) vs Catálogo (Fuera de estreno)
    if (category === 'nowPlaying') {
      try {
        const liveTheatrical = await getTheatricalMovies(countryCode);
        if (liveTheatrical && liveTheatrical.length > 0) {
          list = liveTheatrical;
        } else {
          list = list.filter((m) => m.isInTheatersLocally);
        }
      } catch (err) {
        console.warn('Error fetching live theatrical movies, using fallback:', err);
        list = list.filter((m) => m.isInTheatersLocally);
      }

      // Si el usuario busca dentro de estrenos
      if (searchQuery && searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        list = list.filter(
          (m) =>
            m.title.toLowerCase().includes(q) ||
            m.genres.some((g) => g.toLowerCase().includes(q))
        );
      }

      // Ordenar estrenos por MovieScore o año
      if (sortBy === 'ratingDesc') {
        list.sort((a, b) => (b.ratings.compositeScore || 0) - (a.ratings.compositeScore || 0));
      } else {
        list.sort((a, b) => new Date(b.releaseDate).getTime() - new Date(a.releaseDate).getTime());
      }
    } else {
      // Catálogo general: películas FUERA de estreno (que superaron las 2 semanas o lanzadas en digital)
      try {
        const liveCatalog = await getCatalogMovies({
          decade,
          minRating,
          genre,
          sortBy,
          searchQuery,
          countryCode,
        });
        if (Array.isArray(liveCatalog)) {
          return liveCatalog;
        }
      } catch (err) {
        console.warn('Error fetching live catalog, using fallback:', err);
      }

      list = list.filter((m) => !m.isInTheatersLocally);

      // Filtro por década / época
      if (decade !== 'all') {
        list = list.filter((m) => {
          const y = m.releaseYear;
          if (decade === '2020s') return y >= 2020 && y <= 2029;
          if (decade === '2010s') return y >= 2010 && y <= 2019;
          if (decade === '2000s') return y >= 2000 && y <= 2009;
          if (decade === '90s') return y >= 1990 && y <= 1999;
          if (decade === '80s') return y >= 1980 && y <= 1989;
          if (decade === '70s') return y >= 1970 && y <= 1979;
          if (decade === '60s') return y <= 1969;
          return true;
        });
      }

      // Filtro por Rating Mínimo
      if (minRating && minRating > 0) {
        list = list.filter((m) => (m.ratings.compositeScore || 0) >= minRating);
      }

      // Filtro por Género
      if (genre && genre !== 'all') {
        const normG = genre.toLowerCase();
        list = list.filter((m) => m.genres.some((g) => g.toLowerCase().includes(normG)));
      }

      // Ordenamiento: Por defecto descendente desde la más actual fuera de estreno hasta la más antigua
      if (sortBy === 'yearDesc') {
        list.sort((a, b) => {
          const timeA = new Date(a.releaseDate).getTime();
          const timeB = new Date(b.releaseDate).getTime();
          if (timeA !== timeB) return timeB - timeA;
          return b.releaseYear - a.releaseYear;
        });
      } else if (sortBy === 'ratingDesc') {
        list.sort((a, b) => (b.ratings.compositeScore || 0) - (a.ratings.compositeScore || 0));
      } else if (sortBy === 'criticsDesc') {
        list.sort((a, b) => (b.ratings.rottenTomatoesCritics || 0) - (a.ratings.rottenTomatoesCritics || 0));
      } else if (sortBy === 'audienceDesc') {
        list.sort((a, b) => (b.ratings.rottenTomatoesAudience || 0) - (a.ratings.rottenTomatoesAudience || 0));
      }
    }

    // Buscador general (título, director, género o año)
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter(
        (m) =>
          m.title.toLowerCase().includes(q) ||
          m.director?.toLowerCase().includes(q) ||
          m.genres.some((g) => g.toLowerCase().includes(q)) ||
          m.releaseYear.toString().includes(q)
      );
    }

    return list;
  }

  async getMovieById(id: string): Promise<Movie | null> {
    try {
      const live = await getMovieByIdAction(id);
      if (live) return live;
    } catch (err) {
      console.warn('Error in getMovieByIdAction:', err);
    }

    const found = CURATED_MOVIES.find((m) => m.id === id);
    if (!found) return null;

    const countryCode = this.user?.location.countryCode || 'PE';
    const isTheatrical = Boolean(
      found.theatricalCountries && found.theatricalCountries.includes(countryCode)
    );

    return {
      ...found,
      isInTheatersLocally: isTheatrical,
      theatersPlaying: isTheatrical ? ['Cines de ' + (this.user?.location.country || this.user?.location.city || 'Perú')] : [],
    };
  }

  async getShowtimes(movieId: string, city: string): Promise<CinemaShowtime[]> {
    const normCity = city.trim().toLowerCase();
    const cityData = CITY_SHOWTIMES[normCity] || {};
    return cityData[movieId] || [];
  }

  // --- Reseñas ---
  async getReviews(movieId?: string): Promise<Review[]> {
    try {
      const dbRevs = await getDbReviews(movieId);
      if (dbRevs && dbRevs.length > 0) {
        const localOnly = this.reviews.filter((lr) => !dbRevs.some((dr) => dr.id === lr.id));
        return [...localOnly, ...dbRevs].sort(
          (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );
      }
    } catch (err) {
      console.warn('Error fetching DB reviews:', err);
    }
    let revs = [...this.reviews];
    if (movieId) {
      revs = revs.filter((r) => r.movieId === movieId);
    }
    return revs.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  async submitReview(reviewData: {
    movieId: string;
    movieTitle: string;
    moviePosterUrl?: string;
    movieReleaseYear?: number;
    rating: number;
    comment: string;
    isCommunity?: boolean;
  }): Promise<Review> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para calificar o comentar.');
    }
    const newRev: Review = {
      id: `rev_${Date.now()}`,
      movieId: reviewData.movieId,
      movieTitle: reviewData.movieTitle,
      moviePosterUrl: reviewData.moviePosterUrl,
      movieReleaseYear: reviewData.movieReleaseYear,
      userId: this.user.id,
      userName: this.user.displayName,
      userAvatarUrl: this.user.avatarUrl,
      rating: reviewData.rating,
      comment: reviewData.comment,
      likesCount: 0,
      helpfulCount: 0,
      isCommunity: !!reviewData.isCommunity,
      createdAt: new Date().toISOString(),
      comments: [],
      isLikedByMe: false,
    };

    // Guardar en Neon DB mediante server action
    try {
      await submitDbReview({
        movieId: newRev.movieId,
        movieTitle: newRev.movieTitle,
        moviePosterUrl: newRev.moviePosterUrl,
        movieReleaseYear: newRev.movieReleaseYear,
        userId: newRev.userId,
        userName: newRev.userName,
        userAvatarUrl: newRev.userAvatarUrl,
        rating: newRev.rating,
        comment: newRev.comment,
        isCommunity: newRev.isCommunity,
      });
    } catch (err) {
      console.warn('Error saving review to Neon DB:', err);
    }

    this.reviews = [newRev, ...this.reviews];
    setLocalItem('reviews', this.reviews);
    return newRev;
  }

  async toggleLikeReview(reviewId: string): Promise<Review | null> {
    const idx = this.reviews.findIndex((r) => r.id === reviewId);
    if (idx === -1) return null;
    const rev = { ...this.reviews[idx] };
    if (rev.isLikedByMe) {
      rev.likesCount = Math.max(0, rev.likesCount - 1);
      rev.isLikedByMe = false;
    } else {
      rev.likesCount += 1;
      rev.isLikedByMe = true;
    }
    this.reviews[idx] = rev;
    setLocalItem('reviews', this.reviews);
    return rev;
  }

  async addCommentToReview(reviewId: string, text: string): Promise<Review | null> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para comentar.');
    }
    const idx = this.reviews.findIndex((r) => r.id === reviewId);
    if (idx === -1) return null;
    const rev = { ...this.reviews[idx] };
    const newComment = {
      id: `c_${Date.now()}`,
      reviewId,
      userId: this.user.id,
      userName: this.user.displayName,
      userAvatarUrl: this.user.avatarUrl,
      text,
      createdAt: new Date().toISOString(),
    };
    rev.comments = [...(rev.comments || []), newComment];
    this.reviews[idx] = rev;
    setLocalItem('reviews', this.reviews);
    return rev;
  }

  // --- Amigos ---
  async getFriends(): Promise<Friend[]> {
    try {
      const dbFriends = await getDbFriends();
      if (dbFriends && dbFriends.length > 0) {
        return dbFriends;
      }
    } catch (err) {
      console.warn('Error fetching DB friends:', err);
    }
    return this.friends;
  }

  async addFriend(username: string): Promise<Friend> {
    try {
      const created = await addDbFriend(username);
      this.friends.push(created);
      setLocalItem('friends', this.friends);
      return created;
    } catch (err) {
      console.warn('Error adding DB friend, using local fallback:', err);
    }
    const cleanUser = username.trim().startsWith('@') ? username.trim() : `@${username.trim()}`;
    const newFriend: Friend = {
      id: `friend_${Date.now()}`,
      displayName: cleanUser.replace('@', ''),
      username: cleanUser,
      avatarUrl: `https://images.unsplash.com/photo-${1500000000000 + (Date.now() % 1000000)}?w=200`,
      isMutual: true,
      mutualMoviesCount: 1,
      bio: 'Cinéfilo recién agregado a tu círculo de amigos.',
    };

    this.friends.push(newFriend);
    setLocalItem('friends', this.friends);
    return newFriend;
  }

  async removeFriend(friendId: string): Promise<void> {
    this.friends = this.friends.filter((f) => f.id !== friendId);
    setLocalItem('friends', this.friends);
  }

  // --- Cineclubs / Grupos ---
  async getGroups(): Promise<MovieGroup[]> {
    try {
      const res = await fetch(`${API_BASE}/chats/groups`);
      if (res.ok) {
        const data = await res.json();
        if (data.groups && Array.isArray(data.groups)) {
          return data.groups;
        }
      }
    } catch (err) {
      console.warn('Error fetching API groups:', err);
    }
    return this.groups;
  }

  async createGroup(name: string, description: string, iconEmoji: string = '🎬'): Promise<MovieGroup> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para crear un cineclub.');
    }

    const res = await fetch(`${API_BASE}/chats/groups`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name,
        description,
        iconEmoji,
        creatorId: this.user.id,
        creatorName: this.user.displayName,
      }),
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      const err = new Error(errData.message || 'Error al crear cineclub');
      (err as any).requiresPro = errData.requiresPro;
      (err as any).code = errData.error;
      throw err;
    }

    const data = await res.json();
    return data.group;
  }

  async joinGroupByCode(code: string): Promise<MovieGroup | null> {
    const norm = code.trim().toUpperCase();
    const groups = await this.getGroups();
    const found = groups.find((g) => g.inviteCode.toUpperCase() === norm);
    if (found) {
      return found;
    }
    return null;
  }

  async getGroupMessages(groupId: string, after?: string): Promise<ChatMessage[]> {
    try {
      const url = after
        ? `${API_BASE}/chats/groups/${groupId}/messages?after=${encodeURIComponent(after)}`
        : `${API_BASE}/chats/groups/${groupId}/messages`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        return data.messages || [];
      }
    } catch (err) {
      console.warn('Error fetching group messages:', err);
    }
    return [];
  }

  async sendGroupMessage(groupId: string, message: {
    text: string;
    messageType?: 'text' | 'movie';
    sharedMovie?: Movie;
  }): Promise<ChatMessage> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para enviar mensajes.');
    }

    const res = await fetch(`${API_BASE}/chats/groups/${groupId}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: this.user.id,
        userName: this.user.displayName,
        text: message.text,
        messageType: message.messageType || 'text',
        sharedMovieId: message.sharedMovie?.id,
        sharedMovieTitle: message.sharedMovie?.title,
      }),
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      const err = new Error(errData.message || 'Error al enviar mensaje en cineclub');
      (err as any).requiresPro = errData.requiresPro;
      (err as any).code = errData.error;
      throw err;
    }

    const data = await res.json();
    return data.message;
  }

  // --- Chats Directos 1 a 1 ---
  async getDirectConversations(): Promise<DirectConversation[]> {
    try {
      const res = await fetch(`${API_BASE}/chats/direct`);
      if (res.ok) {
        const data = await res.json();
        if (data.conversations && Array.isArray(data.conversations)) {
          return data.conversations;
        }
      }
    } catch (err) {
      console.warn('Error fetching direct conversations:', err);
    }
    return [];
  }

  async getOrCreateDirectConversation(participant: Friend | { id: string; displayName: string; username: string; avatarUrl?: string }): Promise<DirectConversation> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para abrir un chat directo.');
    }

    const res = await fetch(`${API_BASE}/chats/direct`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        senderId: this.user.id,
        participantId: participant.id,
      }),
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      const err = new Error(errData.message || 'Error al abrir chat directo');
      (err as any).requiresPro = errData.requiresPro;
      (err as any).code = errData.error;
      throw err;
    }

    const data = await res.json();
    return data.conversation;
  }

  async getDirectMessages(conversationId: string, after?: string): Promise<ChatMessage[]> {
    try {
      const url = after
        ? `${API_BASE}/chats/direct/${conversationId}/messages?after=${encodeURIComponent(after)}`
        : `${API_BASE}/chats/direct/${conversationId}/messages`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        return data.messages || [];
      }
    } catch (err) {
      console.warn('Error fetching direct messages:', err);
    }
    return [];
  }

  async sendDirectMessage(conversationId: string, message: {
    text: string;
    messageType?: 'text' | 'movie';
    sharedMovie?: Movie;
    recipientId?: string;
  }): Promise<ChatMessage> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para enviar mensajes.');
    }

    const res = await fetch(`${API_BASE}/chats/direct/${conversationId}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        senderId: this.user.id,
        senderName: this.user.displayName,
        senderAvatarUrl: this.user.avatarUrl,
        recipientId: message.recipientId,
        text: message.text,
        messageType: message.messageType || 'text',
        sharedMovieId: message.sharedMovie?.id,
        sharedMovieTitle: message.sharedMovie?.title,
      }),
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      const err = new Error(errData.message || 'Error al enviar mensaje');
      (err as any).requiresPro = errData.requiresPro;
      (err as any).code = errData.error;
      throw err;
    }

    const data = await res.json();
    return data.message;
  }

  async getFriendsAndCommunity(): Promise<{ friends: Friend[]; community: (Friend & { isFriend: boolean; isPremium?: boolean })[] }> {
    try {
      const res = await fetch(`${API_BASE}/friends`);
      if (res.ok) {
        const data = await res.json();
        return {
          friends: data.friends || [],
          community: data.community || [],
        };
      }
    } catch (err) {
      console.warn('Error fetching friends and community:', err);
    }
    return { friends: [], community: [] };
  }

  // --- Perfil y Ubicación ---
  getCurrentUser(): User | null {
    return this.user;
  }

  login(user: User): User {
    this.user = user;
    setLocalItem('user', user);
    return user;
  }

  logout(): void {
    this.user = null;
    try {
      localStorage.removeItem('moviesocial_user');
    } catch (err) {
      console.warn('Error clearing localStorage user:', err);
    }
  }

  isLoggedIn(): boolean {
    return this.user !== null;
  }

  updateUser(updates: Partial<User>): User | null {
    if (!this.user) return null;
    this.user = { ...this.user, ...updates };
    setLocalItem('user', this.user);
    return this.user;
  }

  setUserCity(location: UserLocation): User | null {
    if (!this.user) return null;
    this.user = { ...this.user, location };
    setLocalItem('user', this.user);
    return this.user;
  }

  getAvailableCities(): UserLocation[] {
    return AVAILABLE_CITIES;
  }

  async getSpotlight(countryCode: string = 'PE'): Promise<CinephileSpotlightData> {
    try {
      return await getCinephileSpotlight(countryCode);
    } catch {
      const fallback = CURATED_MOVIES[0];
      return {
        movie: fallback,
        tagline: "Selección Oficial",
        curatorNote: "Cine imprescindible de culto recomendado por la crítica internacional.",
        projectionFormat: "IMAX • VOSE",
        circleRecommendation: "Aclamada por tu círculo cinéfilo.",
      };
    }
  }

  async getReviewStats(movieId: string) {
    return await getMovieReviewStats(movieId);
  }

  // --- Watchlist ---
  async getWatchlist(userId?: string): Promise<string[]> {
    const targetUserId = userId || this.user?.id;
    if (!targetUserId) return [];
    try {
      const res = await fetch(`${API_BASE}/watchlist?userId=${encodeURIComponent(targetUserId)}`);
      if (res.ok) {
        const data = await res.json();
        return data.movieIds || [];
      }
    } catch (err) {
      console.warn('Error fetching watchlist:', err);
    }
    return [];
  }

  async toggleWatchlist(movie: Movie, userId?: string): Promise<{ inWatchlist: boolean; movieIds: string[] }> {
    const targetUserId = userId || this.user?.id;
    if (!targetUserId) {
      throw new Error('Debes iniciar sesión para guardar películas en tu Watchlist.');
    }
    const res = await fetch(`${API_BASE}/watchlist`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: targetUserId,
        movieId: movie.id,
        movieTitle: movie.title,
        moviePosterUrl: movie.posterURL,
      }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Error al actualizar tu Watchlist');
    }
    const data = await res.json();
    return data;
  }

  // --- Estado personal cinéfilo (Watchlist, Ya la vi, Favorita) & Círculo de amigos ---
  async getMovieStatus(movieId: string, userId?: string): Promise<{
    inWatchlist: boolean;
    isWatched: boolean;
    isFavorite: boolean;
    friendsInterested: Array<{ id: string; displayName: string; avatarUrl?: string }>;
    friendsInterestedCount: number;
  }> {
    const targetUserId = userId || this.user?.id;
    try {
      const url = targetUserId
        ? `${API_BASE}/movies/status?movieId=${encodeURIComponent(movieId)}&userId=${encodeURIComponent(targetUserId)}`
        : `${API_BASE}/movies/status?movieId=${encodeURIComponent(movieId)}`;
      const res = await fetch(url);
      if (res.ok) {
        return await res.json();
      }
    } catch (err) {
      console.warn('Error fetching movie status:', err);
    }
    return {
      inWatchlist: false,
      isWatched: false,
      isFavorite: false,
      friendsInterested: [],
      friendsInterestedCount: 0,
    };
  }

  async toggleMovieStatus(
    movie: Movie,
    action: 'toggle_watchlist' | 'toggle_watched' | 'toggle_favorite',
    userId?: string
  ): Promise<{ inWatchlist: boolean; isWatched: boolean; isFavorite: boolean }> {
    const targetUserId = userId || this.user?.id;
    if (!targetUserId) {
      throw new Error('Debes iniciar sesión para actualizar el estado de esta película.');
    }
    const res = await fetch(`${API_BASE}/movies/status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: targetUserId,
        movieId: movie.id,
        movieTitle: movie.title,
        moviePosterUrl: movie.posterURL,
        action,
      }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Error al actualizar estado');
    }
    return await res.json();
  }
}

export const api = new MovieSocialAPI();

