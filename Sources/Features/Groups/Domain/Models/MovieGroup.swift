import Foundation

/// Modelo de Dominio que representa un Grupo de Cine / Cineclub
public struct MovieGroup: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let iconEmoji: String
    public let creatorId: String
    public let creatorName: String
    public var members: [Friend]
    public var currentMovieId: String?
    public var currentMovieTitle: String?
    public var currentMoviePosterURL: URL?
    public var currentMovieYear: Int?
    public var messagesCount: Int
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        iconEmoji: String = "🎬",
        creatorId: String,
        creatorName: String,
        members: [Friend] = [],
        currentMovieId: String? = nil,
        currentMovieTitle: String? = nil,
        currentMoviePosterURL: URL? = nil,
        currentMovieYear: Int? = nil,
        messagesCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconEmoji = iconEmoji
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.members = members
        self.currentMovieId = currentMovieId
        self.currentMovieTitle = currentMovieTitle
        self.currentMoviePosterURL = currentMoviePosterURL
        self.currentMovieYear = currentMovieYear
        self.messagesCount = messagesCount
        self.createdAt = createdAt
    }
    
    public var totalMembersCount: Int {
        members.count + 1 // Incluye al creador si no está en la lista
    }
}

