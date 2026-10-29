import Foundation

public struct Review: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let userId: String
    public let userName: String
    public let userAvatarURL: URL?
    public let movieId: String
    public let movieTitle: String
    public let moviePosterURL: URL?
    public let movieReleaseYear: Int?
    public let rating: Double // Escala de 1 a 5 (con medios puntos)
    public let comment: String
    public let createdAt: Date
    public var comments: [ReviewComment]
    public var likesCount: Int
    public var isLikedByMe: Bool
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        userName: String,
        userAvatarURL: URL? = nil,
        movieId: String,
        movieTitle: String,
        moviePosterURL: URL? = nil,
        movieReleaseYear: Int? = nil,
        rating: Double,
        comment: String,
        createdAt: Date = Date(),
        comments: [ReviewComment] = [],
        likesCount: Int = 0,
        isLikedByMe: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatarURL = userAvatarURL
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.moviePosterURL = moviePosterURL
        self.movieReleaseYear = movieReleaseYear
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
        self.comments = comments
        self.likesCount = likesCount
        self.isLikedByMe = isLikedByMe
    }
    
    public var formattedRating: String {
        String(format: "%.1f", rating)
    }
}

