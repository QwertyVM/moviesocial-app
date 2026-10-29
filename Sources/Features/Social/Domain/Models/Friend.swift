import Foundation

public struct Friend: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let displayName: String
    public let username: String
    public let avatarURL: URL?
    public var isMutual: Bool
    public let mutualMoviesCount: Int
    
    public init(
        id: String,
        displayName: String,
        username: String,
        avatarURL: URL? = nil,
        isMutual: Bool = true,
        mutualMoviesCount: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
        self.isMutual = isMutual
        self.mutualMoviesCount = mutualMoviesCount
    }
}

