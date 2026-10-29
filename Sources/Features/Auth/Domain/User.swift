import Foundation

public enum AuthProvider: String, Sendable, Codable {
    case apple = "Apple"
    case google = "Google"
    case mock = "Test"
}

public struct UserLocation: Sendable, Codable, Equatable {
    public let city: String
    public let country: String
    public let countryCode: String
    public let flagEmoji: String
    public let isLocal: Bool
    
    public init(
        city: String,
        country: String,
        countryCode: String,
        flagEmoji: String,
        isLocal: Bool = false
    ) {
        self.city = city
        self.country = country
        self.countryCode = countryCode
        self.flagEmoji = flagEmoji
        self.isLocal = isLocal
    }
    
    public var formattedText: String {
        "\(flagEmoji) \(city), \(country)"
    }
}

public struct User: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let email: String
    public var displayName: String
    public var username: String
    public var bio: String
    public var favoriteDirector: String
    public var favoriteGenre: String
    public var avatarEmoji: String
    public var avatarURL: URL?
    public let authProvider: AuthProvider
    public let createdAt: Date
    public var isPremium: Bool
    public var location: UserLocation?
    
    public init(
        id: String,
        email: String,
        displayName: String,
        username: String? = nil,
        bio: String = "Cinéfilo apasionado. Descubriendo grandes historias y compartiendo cine sin ruido.",
        favoriteDirector: String = "Christopher Nolan",
        favoriteGenre: String = "Ciencia Ficción",
        avatarEmoji: String = "🎬",
        avatarURL: URL? = nil,
        authProvider: AuthProvider,
        createdAt: Date = Date(),
        isPremium: Bool = false,
        location: UserLocation? = UserLocation(
            city: "Madrid",
            country: "España",
            countryCode: "ES",
            flagEmoji: "🇪🇸",
            isLocal: true
        )
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.username = username ?? "@\(displayName.lowercased().replacingOccurrences(of: " ", with: ""))"
        self.bio = bio
        self.favoriteDirector = favoriteDirector
        self.favoriteGenre = favoriteGenre
        self.avatarEmoji = avatarEmoji
        self.avatarURL = avatarURL
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.isPremium = isPremium
        self.location = location
    }
}
