import Foundation

public enum AuthProvider: String, Sendable, Codable {
    case apple = "Apple"
    case google = "Google"
    case mock = "Test"
}

public struct User: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let email: String
    public let displayName: String
    public let avatarURL: URL?
    public let authProvider: AuthProvider
    public let createdAt: Date
    
    public init(
        id: String,
        email: String,
        displayName: String,
        avatarURL: URL? = nil,
        authProvider: AuthProvider,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.authProvider = authProvider
        self.createdAt = createdAt
    }
}

