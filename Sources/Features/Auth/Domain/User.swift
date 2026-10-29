import Foundation

public enum AuthProvider: String, Sendable, Codable {
    case apple = "Apple"
    case google = "Google"
    case mock = "Test"
}

public struct UserLocation: Sendable, Codable, Equatable, Hashable {
    public let city: String
    public let country: String
    public let countryCode: String
    public let flagEmoji: String
    public let isLocal: Bool
    public let area: String?
    public let isDeviceLocation: Bool
    
    public init(
        city: String,
        country: String,
        countryCode: String,
        flagEmoji: String,
        isLocal: Bool = false,
        area: String? = nil,
        isDeviceLocation: Bool = false
    ) {
        self.city = city
        self.country = country
        self.countryCode = countryCode
        self.flagEmoji = flagEmoji
        self.isLocal = isLocal
        self.area = area
        self.isDeviceLocation = isDeviceLocation
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.city = try container.decode(String.self, forKey: .city)
        self.country = try container.decode(String.self, forKey: .country)
        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.flagEmoji = try container.decode(String.self, forKey: .flagEmoji)
        self.isLocal = try container.decodeIfPresent(Bool.self, forKey: .isLocal) ?? false
        self.area = try container.decodeIfPresent(String.self, forKey: .area)
        self.isDeviceLocation = try container.decodeIfPresent(Bool.self, forKey: .isDeviceLocation) ?? false
    }
    
    public var formattedText: String {
        "\(flagEmoji) \(city), \(country)"
    }
    
    public var detailedFormattedText: String {
        if let area, !area.isEmpty, area.lowercased() != city.lowercased() {
            return "\(flagEmoji) \(city) (\(area)), \(country)"
        }
        return "\(flagEmoji) \(city), \(country)"
    }
    
    public var hierarchicalFormattedText: String {
        if let area, !area.isEmpty, area.lowercased() != city.lowercased() {
            return "\(flagEmoji) \(country) › \(area) › \(city)"
        }
        return "\(flagEmoji) \(country) › \(city)"
    }
    
    public var shortLabel: String {
        "\(flagEmoji) \(city)"
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
            isLocal: true,
            area: "Comunidad de Madrid"
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
