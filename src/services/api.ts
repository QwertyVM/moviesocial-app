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
import { getTheatricalMovies, getCatalogMovies, getMovieByIdAction } from '@/actions/movies';

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

    // Intentar guardar en backend REST
    try {
      fetch(`${API_BASE}/reviews`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: newRev.id,
          movieId: newRev.movieId,
          movieTitle: newRev.movieTitle,
          moviePosterURL: newRev.moviePosterUrl,
          movieReleaseYear: newRev.movieReleaseYear,
          userId: newRev.userId,
          userName: newRev.userName,
          rating: newRev.rating,
          comment: newRev.comment,
          isCommunity: newRev.isCommunity,
        }),
      }).catch(() => {});
    } catch {}

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
    return this.friends;
  }

  async addFriend(username: string): Promise<Friend> {
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

    // Intentar backend
    try {
      fetch(`${API_BASE}/friends`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: newFriend.id,
          displayName: newFriend.displayName,
          username: newFriend.username,
          avatarURL: newFriend.avatarUrl,
        }),
      }).catch(() => {});
    } catch {}

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
    return this.groups;
  }

  async createGroup(name: string, description: string, iconEmoji: string = '🎬'): Promise<MovieGroup> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para crear un cineclub.');
    }
    const grpId = `grp_${Date.now()}`;
    const code = `CINE-${grpId.slice(-6).toUpperCase()}`;
    const newGroup: MovieGroup = {
      id: grpId,
      name,
      description,
      iconEmoji: iconEmoji || '🎬',
      creatorId: this.user.id,
      creatorName: this.user.displayName,
      inviteCode: code,
      messagesCount: 1,
      membersCount: 1,
      createdAt: new Date().toISOString(),
    };

    try {
      fetch(`${API_BASE}/groups`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: newGroup.id,
          name: newGroup.name,
          description: newGroup.description,
          iconEmoji: newGroup.iconEmoji,
          creatorId: newGroup.creatorId,
          creatorName: newGroup.creatorName,
          inviteCode: newGroup.inviteCode,
        }),
      }).catch(() => {});
    } catch {}

    this.groups.unshift(newGroup);
    setLocalItem('groups', this.groups);

    // Mensaje de bienvenida inicial
    this.groupMessages[grpId] = [
      {
        id: `gmsg_${Date.now()}`,
        groupId: grpId,
        senderId: this.user.id,
        senderName: this.user.displayName,
        text: `¡Bienvenidos al cineclub "${name}"! Usa el código de invitación ${code} para sumar amigos.`,
        messageType: 'text',
        createdAt: new Date().toISOString(),
      },
    ];
    setLocalItem('group_messages', this.groupMessages);

    return newGroup;
  }

  async joinGroupByCode(code: string): Promise<MovieGroup | null> {
    const norm = code.trim().toUpperCase();
    const found = this.groups.find((g) => g.inviteCode.toUpperCase() === norm);
    if (found) {
      found.membersCount = (found.membersCount || 1) + 1;
      setLocalItem('groups', this.groups);
      return found;
    }
    // Si no está local, crear uno ficticio con el código
    const joined: MovieGroup = {
      id: `grp_joined_${Date.now()}`,
      name: `Cineclub ${norm}`,
      description: 'Grupo cinéfilo unido por código de invitación.',
      iconEmoji: '🎟️',
      creatorId: 'external_user',
      creatorName: 'Comunidad',
      inviteCode: norm,
      messagesCount: 1,
      membersCount: 4,
      createdAt: new Date().toISOString(),
    };
    this.groups.push(joined);
    setLocalItem('groups', this.groups);
    return joined;
  }

  async getGroupMessages(groupId: string): Promise<ChatMessage[]> {
    return this.groupMessages[groupId] || [];
  }

  async sendGroupMessage(groupId: string, message: {
    text: string;
    messageType?: 'text' | 'movie';
    sharedMovie?: Movie;
  }): Promise<ChatMessage> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para enviar mensajes.');
    }
    const newMsg: ChatMessage = {
      id: `gmsg_${Date.now()}`,
      groupId,
      senderId: this.user.id,
      senderName: this.user.displayName,
      text: message.text,
      messageType: message.messageType || 'text',
      sharedMovieId: message.sharedMovie?.id,
      sharedMovieTitle: message.sharedMovie?.title,
      sharedMoviePosterUrl: message.sharedMovie?.posterURL,
      sharedMovieScore: message.sharedMovie?.ratings.compositeScore || undefined,
      createdAt: new Date().toISOString(),
    };

    const list = this.groupMessages[groupId] || [];
    this.groupMessages[groupId] = [...list, newMsg];
    setLocalItem('group_messages', this.groupMessages);

    // Actualizar conteo de mensajes
    const grp = this.groups.find((g) => g.id === groupId);
    if (grp) {
      grp.messagesCount += 1;
      setLocalItem('groups', this.groups);
    }

    return newMsg;
  }

  // --- Chats Directos 1 a 1 ---
  async getDirectConversations(): Promise<DirectConversation[]> {
    return this.directConversations;
  }

  async getOrCreateDirectConversation(friend: Friend): Promise<DirectConversation> {
    const existing = this.directConversations.find((c) => c.participant.id === friend.id);
    if (existing) return existing;

    const newConvo: DirectConversation = {
      id: `conv_${friend.id}`,
      participant: friend,
      unreadCount: 0,
      updatedAt: new Date().toISOString(),
    };
    this.directConversations.unshift(newConvo);
    setLocalItem('direct_convos', this.directConversations);
    return newConvo;
  }

  async getDirectMessages(conversationId: string): Promise<ChatMessage[]> {
    return this.directMessages[conversationId] || [];
  }

  async sendDirectMessage(conversationId: string, message: {
    text: string;
    messageType?: 'text' | 'movie';
    sharedMovie?: Movie;
  }): Promise<ChatMessage> {
    if (!this.user) {
      throw new Error('Debes iniciar sesión para enviar mensajes.');
    }
    const newMsg: ChatMessage = {
      id: `dmsg_${Date.now()}`,
      conversationId,
      senderId: this.user.id,
      senderName: this.user.displayName,
      text: message.text,
      messageType: message.messageType || 'text',
      sharedMovieId: message.sharedMovie?.id,
      sharedMovieTitle: message.sharedMovie?.title,
      sharedMoviePosterUrl: message.sharedMovie?.posterURL,
      sharedMovieScore: message.sharedMovie?.ratings.compositeScore || undefined,
      createdAt: new Date().toISOString(),
    };

    const msgs = this.directMessages[conversationId] || [];
    this.directMessages[conversationId] = [...msgs, newMsg];
    setLocalItem('direct_messages', this.directMessages);

    const convo = this.directConversations.find((c) => c.id === conversationId);
    if (convo) {
      convo.lastMessage = newMsg;
      convo.updatedAt = newMsg.createdAt;
      setLocalItem('direct_convos', this.directConversations);
    }

    return newMsg;
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
}

export const api = new MovieSocialAPI();

