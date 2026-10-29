import Foundation

public enum GroupMessageType: String, Sendable, Codable, Equatable {
    case text
    case system
    case movieShare
}

/// Mensaje o comentario dentro de la sala de debate de un grupo (estilo WhatsApp)
public struct GroupMessage: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let groupId: String
    public let userId: String
    public let userName: String
    public let userAvatarURL: URL?
    public let text: String
    public let messageType: GroupMessageType
    public let sharedMovieId: String?
    public let sharedMovieTitle: String?
    public let sharedMoviePosterURL: URL?
    public let sharedMovieYear: Int?
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        groupId: String,
        userId: String,
        userName: String,
        userAvatarURL: URL? = nil,
        text: String,
        messageType: GroupMessageType = .text,
        sharedMovieId: String? = nil,
        sharedMovieTitle: String? = nil,
        sharedMoviePosterURL: URL? = nil,
        sharedMovieYear: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.userId = userId
        self.userName = userName
        self.userAvatarURL = userAvatarURL
        self.text = text
        self.messageType = messageType
        self.sharedMovieId = sharedMovieId
        self.sharedMovieTitle = sharedMovieTitle
        self.sharedMoviePosterURL = sharedMoviePosterURL
        self.sharedMovieYear = sharedMovieYear
        self.createdAt = createdAt
    }
}
