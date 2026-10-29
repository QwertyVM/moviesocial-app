import Foundation

/// Implementación del repositorio social utilizando Swift 6 Actor para concurrencia segura
public actor SocialRepositoryImpl: SocialRepositoryProtocol {
    private var friends: [Friend]
    private var reviews: [Review]
    private var communityReviews: [Review]
    private let database: AppDatabase
    private let apiClient: MovieSocialAPIClient
    
    public init(
        friends: [Friend] = defaultFriends,
        reviews: [Review] = defaultReviews,
        communityReviews: [Review] = defaultCommunityReviews,
        database: AppDatabase = AppDatabase.shared,
        apiClient: MovieSocialAPIClient = MovieSocialAPIClient.shared
    ) {
        self.friends = friends
        self.reviews = reviews
        self.communityReviews = communityReviews
        self.database = database
        self.apiClient = apiClient
    }
    
    public func getFriends() async throws -> [Friend] {
        return friends
    }
    
    public func getFriendsFeed() async throws -> [Review] {
        return reviews
            .filter { !$0.isHistorical }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    public func getUserReviews(userId: String) async throws -> [Review] {
        return reviews.filter { $0.userId == userId && !$0.isHistorical }
    }
    
    public func getReviewsForMovie(movieId: String) async throws -> [Review] {
        return reviews
            .filter { $0.movieId == movieId && !$0.isHistorical }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    public func getCommunityReviewsForMovie(movieId: String) async throws -> [Review] {
        let friendRevs = reviews.filter { $0.movieId == movieId && !$0.isHistorical }
        var nonFriendRevs = communityReviews.filter { $0.movieId == movieId && !$0.isHistorical }
        
        // Si no hay reseñas precargadas para este movieId, generar plantilla dinámica enriquecida
        if nonFriendRevs.isEmpty {
            let generated = generateDynamicCommunityReviews(movieId: movieId)
            communityReviews.append(contentsOf: generated)
            nonFriendRevs = generated
        }
        
        // Devolver combinación ordenada por votos útiles y fecha
        return (friendRevs + nonFriendRevs).sorted {
            if $0.helpfulCount != $1.helpfulCount {
                return $0.helpfulCount > $1.helpfulCount
            }
            return $0.createdAt > $1.createdAt
        }
    }
    
    public func addReview(
        movieId: String,
        movieTitle: String,
        moviePosterURL: URL?,
        movieReleaseYear: Int?,
        rating: Double,
        comment: String,
        user: User
    ) async throws -> Review {
        // Regla de negocio: Una persona solo puede publicar una reseña por película
        if reviews.contains(where: { $0.userId == user.id && $0.movieId == movieId && !$0.isHistorical }) {
            throw SocialError.reviewAlreadyExists
        }
        
        let newReview = Review(
            id: UUID().uuidString,
            userId: user.id,
            userName: user.displayName,
            userAvatarURL: user.avatarURL,
            movieId: movieId,
            movieTitle: movieTitle,
            moviePosterURL: moviePosterURL,
            movieReleaseYear: movieReleaseYear,
            rating: rating,
            comment: comment,
            createdAt: Date(),
            location: user.location ?? UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: true
        )
        
        reviews.insert(newReview, at: 0)
        await database.saveReview(newReview, isCommunity: false)
        
        // Servicio REST: POST /api/reviews
        let req = CreateReviewRequest(
            id: newReview.id,
            movieId: movieId,
            movieTitle: movieTitle,
            moviePosterURL: moviePosterURL?.absoluteString,
            movieReleaseYear: movieReleaseYear,
            userId: user.id,
            userName: user.displayName,
            rating: rating,
            comment: comment,
            isCommunity: false
        )
        _ = try? await apiClient.execute(endpoint: "/reviews", method: .post, body: req)
        
        return newReview
    }
    
    public func editReview(
        reviewId: String,
        rating: Double,
        comment: String,
        currentDate: Date = Date()
    ) async throws -> Review {
        guard let index = reviews.firstIndex(where: { $0.id == reviewId }) else {
            throw SocialError.reviewNotFound
        }
        
        let current = reviews[index]
        let passedThreeMonths = Review.hasPassedMoreThanThreeMonths(from: current.createdAt, to: currentDate)
        
        if passedThreeMonths {
            // "si quiere editarla su primera reseña deberia quedar como historico si ya pasaron mas de 3 meses"
            if reviews[index].history.isEmpty {
                let firstReviewEntry = ReviewHistoryEntry(
                    id: UUID().uuidString,
                    rating: current.rating,
                    comment: current.comment,
                    createdAt: current.createdAt,
                    archivedAt: currentDate
                )
                reviews[index].history.append(firstReviewEntry)
            } else {
                let previousEntry = ReviewHistoryEntry(
                    id: UUID().uuidString,
                    rating: current.rating,
                    comment: current.comment,
                    createdAt: current.updatedAt ?? current.createdAt,
                    archivedAt: currentDate
                )
                reviews[index].history.append(previousEntry)
            }
            
            // Registro histórico archivado en el repositorio
            let historicalSnapshot = Review(
                id: "\(current.id)_historical_\(UUID().uuidString.prefix(6))",
                userId: current.userId,
                userName: current.userName,
                userAvatarURL: current.userAvatarURL,
                movieId: current.movieId,
                movieTitle: current.movieTitle,
                moviePosterURL: current.moviePosterURL,
                movieReleaseYear: current.movieReleaseYear,
                rating: current.rating,
                comment: current.comment,
                createdAt: current.createdAt,
                updatedAt: currentDate,
                comments: current.comments,
                likesCount: current.likesCount,
                isLikedByMe: current.isLikedByMe,
                location: current.location,
                isFriend: current.isFriend,
                helpfulCount: current.helpfulCount,
                isHelpfulByMe: current.isHelpfulByMe,
                isHistorical: true,
                history: []
            )
            reviews.append(historicalSnapshot)
        }
        
        reviews[index].rating = rating
        reviews[index].comment = comment
        reviews[index].updatedAt = currentDate
        await database.saveReview(reviews[index], isCommunity: false)
        
        // Servicio REST: PUT /api/reviews/:id
        let updateReq = UpdateReviewRequest(rating: rating, comment: comment)
        _ = try? await apiClient.execute(endpoint: "/reviews/\(reviewId)", method: .put, body: updateReq)
        
        return reviews[index]
    }
    
    public func getReviewHistory(reviewId: String) async throws -> [ReviewHistoryEntry] {
        guard let review = reviews.first(where: { $0.id == reviewId }) else {
            throw SocialError.reviewNotFound
        }
        return review.history
    }
    
    public func addCommentToReview(
        reviewId: String,
        text: String,
        user: User
    ) async throws -> ReviewComment {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "Social", code: 400, userInfo: [NSLocalizedDescriptionKey: "El comentario no puede estar vacío"])
        }
        
        let newComment = ReviewComment(
            id: UUID().uuidString,
            reviewId: reviewId,
            userId: user.id,
            userName: user.displayName,
            userAvatarURL: user.avatarURL,
            text: trimmed,
            createdAt: Date()
        )
        
        if let index = reviews.firstIndex(where: { $0.id == reviewId }) {
            reviews[index].comments.append(newComment)
            await database.saveReview(reviews[index], isCommunity: false)
            return newComment
        } else if let index = communityReviews.firstIndex(where: { $0.id == reviewId }) {
            communityReviews[index].comments.append(newComment)
            await database.saveReview(communityReviews[index], isCommunity: true)
            return newComment
        } else {
            throw NSError(domain: "Social", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reseña no encontrada"])
        }
    }
    
    public func toggleLikeReview(
        reviewId: String,
        userId: String
    ) async throws -> (isLiked: Bool, newCount: Int) {
        if let index = reviews.firstIndex(where: { $0.id == reviewId }) {
            let willBeLiked = !reviews[index].isLikedByMe
            reviews[index].isLikedByMe = willBeLiked
            reviews[index].likesCount = willBeLiked ? reviews[index].likesCount + 1 : max(0, reviews[index].likesCount - 1)
            await database.saveReview(reviews[index], isCommunity: false)
            return (reviews[index].isLikedByMe, reviews[index].likesCount)
        } else if let index = communityReviews.firstIndex(where: { $0.id == reviewId }) {
            let willBeLiked = !communityReviews[index].isLikedByMe
            communityReviews[index].isLikedByMe = willBeLiked
            communityReviews[index].likesCount = willBeLiked ? communityReviews[index].likesCount + 1 : max(0, communityReviews[index].likesCount - 1)
            await database.saveReview(communityReviews[index], isCommunity: true)
            return (communityReviews[index].isLikedByMe, communityReviews[index].likesCount)
        } else {
            throw NSError(domain: "Social", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reseña no encontrada"])
        }
    }
    
    public func toggleHelpfulReview(
        reviewId: String,
        userId: String
    ) async throws -> (isHelpful: Bool, newCount: Int) {
        if let index = communityReviews.firstIndex(where: { $0.id == reviewId }) {
            let willBeHelpful = !communityReviews[index].isHelpfulByMe
            communityReviews[index].isHelpfulByMe = willBeHelpful
            communityReviews[index].helpfulCount = willBeHelpful ? communityReviews[index].helpfulCount + 1 : max(0, communityReviews[index].helpfulCount - 1)
            await database.saveReview(communityReviews[index], isCommunity: true)
            return (communityReviews[index].isHelpfulByMe, communityReviews[index].helpfulCount)
        } else if let index = reviews.firstIndex(where: { $0.id == reviewId }) {
            let willBeHelpful = !reviews[index].isHelpfulByMe
            reviews[index].isHelpfulByMe = willBeHelpful
            reviews[index].helpfulCount = willBeHelpful ? reviews[index].helpfulCount + 1 : max(0, reviews[index].helpfulCount - 1)
            await database.saveReview(reviews[index], isCommunity: false)
            return (reviews[index].isHelpfulByMe, reviews[index].helpfulCount)
        } else {
            throw NSError(domain: "Social", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reseña no encontrada"])
        }
    }
    
    public func addFriend(username: String) async throws -> Friend {
        let cleaned = username.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else {
            throw NSError(domain: "Social", code: 400, userInfo: [NSLocalizedDescriptionKey: "Usuario no válido"])
        }
        
        let newFriend = Friend(
            id: UUID().uuidString,
            displayName: cleaned.capitalized,
            username: "@\(cleaned.lowercased())",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
            isMutual: true,
            mutualMoviesCount: 1
        )
        friends.append(newFriend)
        await database.saveFriend(newFriend)
        
        // Servicio REST: POST /api/friends
        let friendReq = CreateFriendRequest(
            id: newFriend.id,
            displayName: newFriend.displayName,
            username: newFriend.username,
            avatarURL: newFriend.avatarURL?.absoluteString
        )
        _ = try? await apiClient.execute(endpoint: "/friends", method: .post, body: friendReq)
        
        return newFriend
    }
    
    public func removeFriend(friendId: String) async throws {
        friends.removeAll { $0.id == friendId }
        await database.removeFriend(id: friendId)
        
        // Servicio REST: DELETE /api/friends/:id
        _ = try? await apiClient.execute(endpoint: "/friends/\(friendId)", method: .delete)
    }
    
    // MARK: - Dynamic Generator for Any Movie
    
    private func generateDynamicCommunityReviews(movieId: String) -> [Review] {
        return [
            Review(
                id: "comm_gen_loc_1_\(movieId)",
                userId: "user_loc_carlos",
                userName: "Carlos Navarro",
                userAvatarURL: URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200"),
                movieId: movieId,
                movieTitle: "Película Seleccionada",
                rating: 4.5,
                comment: "Vista en cines locales de Madrid. La dirección artística y el sonido envolvente me dejaron fascinado. Una recomendación segura.",
                createdAt: Date().addingTimeInterval(-14400),
                likesCount: 14,
                isLikedByMe: false,
                location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
                isFriend: false,
                helpfulCount: 22,
                isHelpfulByMe: false
            ),
            Review(
                id: "comm_gen_loc_2_\(movieId)",
                userId: "user_loc_valen",
                userName: "Valentina Soto",
                userAvatarURL: URL(string: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200"),
                movieId: movieId,
                movieTitle: "Película Seleccionada",
                rating: 5.0,
                comment: "Increíble cómo maneja el ritmo narrativo. La vi con amigos en Barcelona y no paramos de debatirla después.",
                createdAt: Date().addingTimeInterval(-28800),
                likesCount: 9,
                isLikedByMe: false,
                location: UserLocation(city: "Barcelona", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
                isFriend: false,
                helpfulCount: 17,
                isHelpfulByMe: false
            ),
            Review(
                id: "comm_gen_int_1_\(movieId)",
                userId: "user_int_kenji",
                userName: "Kenji Sato",
                userAvatarURL: URL(string: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200"),
                movieId: movieId,
                movieTitle: "Película Seleccionada",
                rating: 4.5,
                comment: "池袋のIMAXで鑑賞。映像美と演出の緻密さに圧倒されました。世界中の映画ファンに体験してほしい傑作です。(Visto en Tokio, una experiencia cinematográfica impresionante).",
                createdAt: Date().addingTimeInterval(-43200),
                likesCount: 31,
                isLikedByMe: false,
                location: UserLocation(city: "Tokio", country: "Japón", countryCode: "JP", flagEmoji: "🇯🇵", isLocal: false),
                isFriend: false,
                helpfulCount: 45,
                isHelpfulByMe: false
            ),
            Review(
                id: "comm_gen_int_2_\(movieId)",
                userId: "user_int_sarah",
                userName: "Sarah Jenkins",
                userAvatarURL: URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200"),
                movieId: movieId,
                movieTitle: "Película Seleccionada",
                rating: 5.0,
                comment: "Saw this in NYC Lincoln Square. Breathtaking cinematography and powerful character dynamics. A true modern masterpiece.",
                createdAt: Date().addingTimeInterval(-60000),
                likesCount: 26,
                isLikedByMe: false,
                location: UserLocation(city: "Nueva York", country: "EE. UU.", countryCode: "US", flagEmoji: "🇺🇸", isLocal: false),
                isFriend: false,
                helpfulCount: 38,
                isHelpfulByMe: false
            ),
            Review(
                id: "comm_gen_int_3_\(movieId)",
                userId: "user_int_jeanluc",
                userName: "Jean-Luc Moreau",
                userAvatarURL: URL(string: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200"),
                movieId: movieId,
                movieTitle: "Película Seleccionada",
                rating: 4.0,
                comment: "Une mise en scène brillante et élégante. Les thématiques universelles résonnent bien au-delà des frontières.",
                createdAt: Date().addingTimeInterval(-72000),
                likesCount: 18,
                isLikedByMe: false,
                location: UserLocation(city: "París", country: "Francia", countryCode: "FR", flagEmoji: "🇫🇷", isLocal: false),
                isFriend: false,
                helpfulCount: 19,
                isHelpfulByMe: false
            )
        ]
    }
    
    // MARK: - Curated Static Data
    
    public static let defaultFriends: [Friend] = [
        Friend(
            id: "friend_1",
            displayName: "Lucas Benítez",
            username: "@lucasfilm",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
            isMutual: true,
            mutualMoviesCount: 14,
            isOnline: true
        ),
        Friend(
            id: "friend_2",
            displayName: "Camila Vega",
            username: "@camicine",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200"),
            isMutual: true,
            mutualMoviesCount: 22,
            isOnline: true
        ),
        Friend(
            id: "friend_3",
            displayName: "Mateo Rossi",
            username: "@mrossi",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200"),
            isMutual: true,
            mutualMoviesCount: 8,
            isOnline: false
        ),
        Friend(
            id: "friend_4",
            displayName: "Sofía Alarcón",
            username: "@sofiacine",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200"),
            isMutual: true,
            mutualMoviesCount: 19,
            isOnline: true
        ),
        Friend(
            id: "friend_5",
            displayName: "Diego Mendoza",
            username: "@diegofilms",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200"),
            isMutual: false,
            mutualMoviesCount: 5,
            isOnline: false
        )
    ]
    
    public static let defaultReviews: [Review] = [
        Review(
            id: "rev_1",
            userId: "friend_1",
            userName: "Lucas Benítez",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 5.0,
            comment: "Una experiencia audiovisual colosal. El diseño sonoro en cine te deja sin respiración. Villeneuve lo volvió a hacer.",
            createdAt: Date().addingTimeInterval(-7200),
            comments: [
                ReviewComment(
                    id: "comm_1_1",
                    reviewId: "rev_1",
                    userId: "friend_2",
                    userName: "Camila Vega",
                    userAvatarURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200"),
                    text: "¡Totalmente! La escena montando el gusano en IMAX es inolvidable. ¿La viste en versión original?",
                    createdAt: Date().addingTimeInterval(-5400)
                ),
                ReviewComment(
                    id: "comm_1_2",
                    reviewId: "rev_1",
                    userId: "friend_3",
                    userName: "Mateo Rossi",
                    userAvatarURL: URL(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200"),
                    text: "Austin Butler como Feyd-Rautha se roba cada minuto en blanco y negro. Cine puro.",
                    createdAt: Date().addingTimeInterval(-3600)
                )
            ],
            likesCount: 5,
            isLikedByMe: true,
            location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: true,
            helpfulCount: 14,
            isHelpfulByMe: false
        ),
        Review(
            id: "rev_2",
            userId: "friend_2",
            userName: "Camila Vega",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200"),
            movieId: "238",
            movieTitle: "El Padrino",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            movieReleaseYear: 1972,
            rating: 5.0,
            comment: "La volví a ver en pantalla grande. El ritmo, la fotografía de Gordon Willis y la mirada de Al Pacino son insuperables.",
            createdAt: Date().addingTimeInterval(-120 * 86400),
            updatedAt: Date().addingTimeInterval(-10 * 86400),
            comments: [
                ReviewComment(
                    id: "comm_2_1",
                    reviewId: "rev_2",
                    userId: "friend_1",
                    userName: "Lucas Benítez",
                    userAvatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
                    text: "Esa secuencia final en la iglesia entremezclada con los ajustes de cuentas es la cúspide del cine.",
                    createdAt: Date().addingTimeInterval(-82000)
                )
            ],
            likesCount: 8,
            isLikedByMe: false,
            location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: true,
            helpfulCount: 9,
            isHelpfulByMe: false,
            history: [
                ReviewHistoryEntry(
                    id: "hist_rev_2_first",
                    rating: 4.5,
                    comment: "Excelente clásico, aunque el primer visionado se me hizo algo lento en su tramo medio.",
                    createdAt: Date().addingTimeInterval(-120 * 86400),
                    archivedAt: Date().addingTimeInterval(-10 * 86400)
                )
            ]
        ),
        Review(
            id: "rev_3",
            userId: "friend_3",
            userName: "Mateo Rossi",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200"),
            movieId: "1022789",
            movieTitle: "Intensamente 2",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg"),
            movieReleaseYear: 2024,
            rating: 4.0,
            comment: "Ansiedad retratada de forma brillante. Muy divertida y conmovedora.",
            createdAt: Date().addingTimeInterval(-172800),
            comments: [],
            likesCount: 3,
            isLikedByMe: false,
            location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: true,
            helpfulCount: 6,
            isHelpfulByMe: false
        ),
        Review(
            id: "rev_user_1",
            userId: "apple_user_101",
            userName: "Alex Rivera",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
            movieId: "157336",
            movieTitle: "Interstellar",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
            movieReleaseYear: 2014,
            rating: 5.0,
            comment: "Una obra maestra de la ciencia ficción y el amor a través de las dimensiones.",
            createdAt: Date().addingTimeInterval(-86400 * 3),
            comments: [],
            likesCount: 12,
            isLikedByMe: false,
            location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: false,
            helpfulCount: 15,
            isHelpfulByMe: false
        ),
        Review(
            id: "rev_user_2",
            userId: "apple_user_101",
            userName: "Alex Rivera",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
            movieId: "27205",
            movieTitle: "El Origen",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg"),
            movieReleaseYear: 2010,
            rating: 4.5,
            comment: "El diseño narrativo y los niveles de sueño siguen siendo revolucionarios.",
            createdAt: Date().addingTimeInterval(-86400 * 10),
            comments: [],
            likesCount: 7,
            isLikedByMe: false,
            location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: false,
            helpfulCount: 8,
            isHelpfulByMe: false
        )
    ]
    
    public static let defaultCommunityReviews: [Review] = [
        // MARK: - Duna: Parte dos (693134) - Locales (No Amigos)
        Review(
            id: "comm_dune_loc_1",
            userId: "user_nonfriend_carlos",
            userName: "Carlos Navarro",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 4.5,
            comment: "Vista en Cines Callao en Madrid. El sonido es brutal con los ornitópteros y el gusano. Hacía tiempo que no sentía temblar las butacas en una sala. Una obra maestra moderna.",
            createdAt: Date().addingTimeInterval(-10800),
            comments: [],
            likesCount: 19,
            isLikedByMe: false,
            location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: false,
            helpfulCount: 34,
            isHelpfulByMe: false
        ),
        Review(
            id: "comm_dune_loc_2",
            userId: "user_nonfriend_valen",
            userName: "Valentina Soto",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 5.0,
            comment: "La vi en la sala Phenomena de Barcelona en VOSE. La química entre Chalamet y Zendaya sostiene la tragedia política a la perfección.",
            createdAt: Date().addingTimeInterval(-21600),
            comments: [],
            likesCount: 15,
            isLikedByMe: false,
            location: UserLocation(city: "Barcelona", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: false,
            helpfulCount: 28,
            isHelpfulByMe: false
        ),
        Review(
            id: "comm_dune_loc_3",
            userId: "user_nonfriend_diego",
            userName: "Diego Álvarez",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 4.0,
            comment: "Sensación total de inmersión en Kinépolis Valencia. El tramo final acelera un poco los libros, pero la ambientación es impecable.",
            createdAt: Date().addingTimeInterval(-45000),
            comments: [],
            likesCount: 11,
            isLikedByMe: false,
            location: UserLocation(city: "Valencia", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: false,
            helpfulCount: 18,
            isHelpfulByMe: false
        ),
        
        // MARK: - Duna: Parte dos (693134) - Internacionales (No Amigos)
        Review(
            id: "comm_dune_int_1",
            userId: "user_nonfriend_kenji",
            userName: "Kenji Sato",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 5.0,
            comment: "池袋グランドシネマサンシャインのIMAXレーザーGTで鑑賞。ハルコンネン母星のモノクロ赤外線シーンは映画史に残る美しさ。オースティン・バトラーの存在感に鳥肌が立った。",
            createdAt: Date().addingTimeInterval(-32400),
            comments: [],
            likesCount: 42,
            isLikedByMe: false,
            location: UserLocation(city: "Tokio", country: "Japón", countryCode: "JP", flagEmoji: "🇯🇵", isLocal: false),
            isFriend: false,
            helpfulCount: 67,
            isHelpfulByMe: false
        ),
        Review(
            id: "comm_dune_int_2",
            userId: "user_nonfriend_sarah",
            userName: "Sarah Jenkins",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 5.0,
            comment: "Saw this on 70mm IMAX at AMC Lincoln Square in New York. The scale is staggering. Villeneuve took Herbert's warning on charismatic leaders and delivered cinema at its peak.",
            createdAt: Date().addingTimeInterval(-50000),
            comments: [],
            likesCount: 38,
            isLikedByMe: false,
            location: UserLocation(city: "Nueva York", country: "EE. UU.", countryCode: "US", flagEmoji: "🇺🇸", isLocal: false),
            isFriend: false,
            helpfulCount: 54,
            isHelpfulByMe: false
        ),
        Review(
            id: "comm_dune_int_3",
            userId: "user_nonfriend_jeanluc",
            userName: "Jean-Luc Moreau",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 4.5,
            comment: "Au Grand Rex à Paris. Une œuvre épique d'une rare élégance visuelle. Greig Fraser signe une photographie magistrale.",
            createdAt: Date().addingTimeInterval(-64000),
            comments: [],
            likesCount: 27,
            isLikedByMe: false,
            location: UserLocation(city: "París", country: "Francia", countryCode: "FR", flagEmoji: "🇫🇷", isLocal: false),
            isFriend: false,
            helpfulCount: 39,
            isHelpfulByMe: false
        ),
        Review(
            id: "comm_dune_int_4",
            userId: "user_nonfriend_minjun",
            userName: "Min-jun Kim",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200"),
            movieId: "693134",
            movieTitle: "Duna: Parte dos",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            movieReleaseYear: 2024,
            rating: 5.0,
            comment: "용산 아이맥스에서 관람. 한스 짐머의 사운드트랙과 모래벌레 시퀀스는 극장에서만 느낄 수 있는 압도적인 전율을 선사합니다.",
            createdAt: Date().addingTimeInterval(-80000),
            comments: [],
            likesCount: 29,
            isLikedByMe: false,
            location: UserLocation(city: "Seúl", country: "Corea del Sur", countryCode: "KR", flagEmoji: "🇰🇷", isLocal: false),
            isFriend: false,
            helpfulCount: 41,
            isHelpfulByMe: false
        ),
        
        // MARK: - El Padrino (238) - Comunidad
        Review(
            id: "comm_godfather_loc_1",
            userId: "user_nonfriend_alvaro",
            userName: "Álvaro Gómez",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200"),
            movieId: "238",
            movieTitle: "El Padrino",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            movieReleaseYear: 1972,
            rating: 5.0,
            comment: "Proyección en 35mm en el Cine Doré de Madrid. Cada claroscuro de Gordon Willis y cada respiración de Marlon Brando recuerdan por qué amamos el cine.",
            createdAt: Date().addingTimeInterval(-92000),
            comments: [],
            likesCount: 22,
            isLikedByMe: false,
            location: UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            isFriend: false,
            helpfulCount: 30,
            isHelpfulByMe: false
        ),
        Review(
            id: "comm_godfather_int_1",
            userId: "user_nonfriend_marco",
            userName: "Marco Bertolini",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=200"),
            movieId: "238",
            movieTitle: "El Padrino",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            movieReleaseYear: 1972,
            rating: 5.0,
            comment: "Capolavoro eterno visto al Cinema Farnese a Roma. La colonna sonora di Nino Rota è scolpita nella nostra anima.",
            createdAt: Date().addingTimeInterval(-100000),
            comments: [],
            likesCount: 35,
            isLikedByMe: false,
            location: UserLocation(city: "Roma", country: "Italia", countryCode: "IT", flagEmoji: "🇮🇹", isLocal: false),
            isFriend: false,
            helpfulCount: 48,
            isHelpfulByMe: false
        )
    ]
}
