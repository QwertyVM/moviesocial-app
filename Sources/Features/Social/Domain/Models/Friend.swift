import Foundation

public struct Friend: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let displayName: String
    public let username: String
    public let avatarURL: URL?
    public var isMutual: Bool
    public let mutualMoviesCount: Int
    public var isOnline: Bool
    
    /// Alias para claridad de afinidad cinéfila (películas compartidas con calificación > 3★)
    public var sharedTastesCount: Int {
        mutualMoviesCount
    }
    
    public init(
        id: String,
        displayName: String,
        username: String,
        avatarURL: URL? = nil,
        isMutual: Bool = true,
        mutualMoviesCount: Int = 0,
        isOnline: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
        self.isMutual = isMutual
        self.mutualMoviesCount = mutualMoviesCount
        self.isOnline = isOnline
    }
}
