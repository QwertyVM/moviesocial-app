import Foundation

/// Modelo de dominio que representa una conversación One-to-One (1 a 1) entre dos cinéfilos
public struct DirectConversation: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let participant: Friend
    public var lastMessage: DirectMessage?
    public var unreadCount: Int
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        participant: Friend,
        lastMessage: DirectMessage? = nil,
        unreadCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.participant = participant
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.updatedAt = updatedAt
    }
}
