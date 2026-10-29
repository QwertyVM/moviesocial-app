import Foundation

// MARK: - DTOs de Solicitudes y Respuestas para la API REST

public struct CreateReviewRequest: Encodable, Sendable {
    public let id: String
    public let movieId: String
    public let movieTitle: String
    public let moviePosterURL: String?
    public let movieReleaseYear: Int?
    public let userId: String
    public let userName: String
    public let rating: Double
    public let comment: String
    public let isCommunity: Bool
    
    public init(id: String, movieId: String, movieTitle: String, moviePosterURL: String?, movieReleaseYear: Int?, userId: String, userName: String, rating: Double, comment: String, isCommunity: Bool) {
        self.id = id
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.moviePosterURL = moviePosterURL
        self.movieReleaseYear = movieReleaseYear
        self.userId = userId
        self.userName = userName
        self.rating = rating
        self.comment = comment
        self.isCommunity = isCommunity
    }
}

public struct UpdateReviewRequest: Encodable, Sendable {
    public let rating: Double?
    public let comment: String?
    
    public init(rating: Double? = nil, comment: String? = nil) {
        self.rating = rating
        self.comment = comment
    }
}

public struct CreateFriendRequest: Encodable, Sendable {
    public let id: String
    public let displayName: String
    public let username: String
    public let avatarURL: String?
    
    public init(id: String, displayName: String, username: String, avatarURL: String?) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
    }
}

public struct CreateGroupRequest: Encodable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let iconEmoji: String
    public let creatorId: String
    public let creatorName: String
    public let inviteCode: String
    
    public init(id: String, name: String, description: String, iconEmoji: String, creatorId: String, creatorName: String, inviteCode: String) {
        self.id = id
        self.name = name
        self.description = description
        self.iconEmoji = iconEmoji
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.inviteCode = inviteCode
    }
}

public struct SendGroupMessageRequest: Encodable, Sendable {
    public let id: String
    public let userId: String
    public let userName: String
    public let text: String
    public let messageType: String
    public let sharedMovieId: String?
    public let sharedMovieTitle: String?
    
    public init(id: String, userId: String, userName: String, text: String, messageType: String, sharedMovieId: String?, sharedMovieTitle: String?) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.text = text
        self.messageType = messageType
        self.sharedMovieId = sharedMovieId
        self.sharedMovieTitle = sharedMovieTitle
    }
}

public struct UpdateUserRequest: Encodable, Sendable {
    public let displayName: String?
    public let username: String?
    public let bio: String?
    public let city: String?
    public let country: String?
    
    public init(displayName: String? = nil, username: String? = nil, bio: String? = nil, city: String? = nil, country: String? = nil) {
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.city = city
        self.country = country
    }
}

public struct GenericAPIResponse: Decodable, Sendable {
    public let message: String?
    public let id: String?
    public let error: String?
}

public struct ServerHealthResponse: Decodable, Sendable {
    public let status: String
    public let database: String
    public let server: String
    public let version: String
    public let stats: [String: Int]?
}
