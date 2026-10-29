import Foundation

/// Modelo que representa un comentario o respuesta que deja un amigo en una reseña u opinión
public struct ReviewComment: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let reviewId: String
    public let userId: String
    public let userName: String
    public let userAvatarURL: URL?
    public let text: String
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        reviewId: String,
        userId: String,
        userName: String,
        userAvatarURL: URL? = nil,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reviewId = reviewId
        self.userId = userId
        self.userName = userName
        self.userAvatarURL = userAvatarURL
        self.text = text
        self.createdAt = createdAt
    }
}
