import Foundation

/// Implementación del repositorio social utilizando Swift 6 Actor para concurrencia segura
public actor SocialRepositoryImpl: SocialRepositoryProtocol {
    private var friends: [Friend]
    private var reviews: [Review]
    
    public init(friends: [Friend] = defaultFriends, reviews: [Review] = defaultReviews) {
        self.friends = friends
        self.reviews = reviews
    }
    
    public func getFriends() async throws -> [Friend] {
        return friends
    }
    
    public func getFriendsFeed() async throws -> [Review] {
        return reviews.sorted { $0.createdAt > $1.createdAt }
    }
    
    public func getReviewsForMovie(movieId: String) async throws -> [Review] {
        return reviews
            .filter { $0.movieId == movieId }
            .sorted { $0.createdAt > $1.createdAt }
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
            createdAt: Date()
        )
        
        reviews.insert(newReview, at: 0)
        return newReview
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
        
        guard let index = reviews.firstIndex(where: { $0.id == reviewId }) else {
            throw NSError(domain: "Social", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reseña no encontrada"])
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
        
        reviews[index].comments.append(newComment)
        return newComment
    }
    
    public func toggleLikeReview(
        reviewId: String,
        userId: String
    ) async throws -> (isLiked: Bool, newCount: Int) {
        guard let index = reviews.firstIndex(where: { $0.id == reviewId }) else {
            throw NSError(domain: "Social", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reseña no encontrada"])
        }
        
        let willBeLiked = !reviews[index].isLikedByMe
        reviews[index].isLikedByMe = willBeLiked
        if willBeLiked {
            reviews[index].likesCount += 1
        } else {
            reviews[index].likesCount = max(0, reviews[index].likesCount - 1)
        }
        
        return (reviews[index].isLikedByMe, reviews[index].likesCount)
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
        return newFriend
    }
    
    public static let defaultFriends: [Friend] = [
        Friend(
            id: "friend_1",
            displayName: "Lucas Benítez",
            username: "@lucasfilm",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
            isMutual: true,
            mutualMoviesCount: 14
        ),
        Friend(
            id: "friend_2",
            displayName: "Camila Vega",
            username: "@camicine",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200"),
            isMutual: true,
            mutualMoviesCount: 22
        ),
        Friend(
            id: "friend_3",
            displayName: "Mateo Rossi",
            username: "@mrossi",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200"),
            isMutual: true,
            mutualMoviesCount: 8
        )
    ]
    
    public static let defaultReviews: [Review] = [
        Review(
            id: "rev_1",
            userId: "friend_1",
            userName: "Lucas Benítez",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
            movieId: "693134",
            movieTitle: "Dune: Parte Dos",
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
            isLikedByMe: true
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
            createdAt: Date().addingTimeInterval(-86400),
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
            isLikedByMe: false
        ),
        Review(
            id: "rev_3",
            userId: "friend_3",
            userName: "Mateo Rossi",
            userAvatarURL: URL(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200"),
            movieId: "1022789",
            movieTitle: "Del Revés 2",
            moviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg"),
            movieReleaseYear: 2024,
            rating: 4.0,
            comment: "Ansiedad retratada de forma brillante. Muy divertida y conmovedora.",
            createdAt: Date().addingTimeInterval(-172800),
            comments: [],
            likesCount: 3,
            isLikedByMe: false
        )
    ]
}
