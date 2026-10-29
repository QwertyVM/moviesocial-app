import Foundation

public enum DirectMessageType: String, Sendable, Codable, Equatable, Hashable {
    case text
    case movieShare
    case system
}

/// Mensaje en una conversación One-to-One (1 a 1) entre dos usuarios
public struct DirectMessage: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let conversationId: String
    public let senderId: String
    public let senderName: String
    public let senderAvatarURL: URL?
    public let recipientId: String
    public let text: String
    public let messageType: DirectMessageType
    public let sharedMovieId: String?
    public let sharedMovieTitle: String?
    public let sharedMoviePosterURL: URL?
    public let sharedMovieYear: Int?
    public var isRead: Bool
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        conversationId: String,
        senderId: String,
        senderName: String,
        senderAvatarURL: URL? = nil,
        recipientId: String,
        text: String,
        messageType: DirectMessageType = .text,
        sharedMovieId: String? = nil,
        sharedMovieTitle: String? = nil,
        sharedMoviePosterURL: URL? = nil,
        sharedMovieYear: Int? = nil,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.senderAvatarURL = senderAvatarURL
        self.recipientId = recipientId
        self.text = text
        self.messageType = messageType
        self.sharedMovieId = sharedMovieId
        self.sharedMovieTitle = sharedMovieTitle
        self.sharedMoviePosterURL = sharedMoviePosterURL
        self.sharedMovieYear = sharedMovieYear
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
