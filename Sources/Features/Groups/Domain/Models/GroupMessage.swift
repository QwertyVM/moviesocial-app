import Foundation

/// Mensaje o comentario dentro de la sala de debate de un grupo
public struct GroupMessage: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let groupId: String
    public let userId: String
    public let userName: String
    public let userAvatarURL: URL?
    public let text: String
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        groupId: String,
        userId: String,
        userName: String,
        userAvatarURL: URL? = nil,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.userId = userId
        self.userName = userName
        self.userAvatarURL = userAvatarURL
        self.text = text
        self.createdAt = createdAt
    }
}

