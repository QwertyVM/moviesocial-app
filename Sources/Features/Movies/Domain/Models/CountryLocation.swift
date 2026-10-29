import Foundation

/// Representa una división territorial o área cinematográfica específica dentro de un país
public struct AreaLocation: Identifiable, Sendable, Codable, Equatable, Hashable {
    public var id: String { "\(city)_\(area)_\(countryCode)" }
    public let city: String
    public let area: String
    public let country: String
    public let countryCode: String
    public let flagEmoji: String
    public let prominentTheaters: [String]
    
    public init(
        city: String,
        area: String,
        country: String,
        countryCode: String,
        flagEmoji: String,
        prominentTheaters: [String] = []
    ) {
        self.city = city
        self.area = area
        self.country = country
        self.countryCode = countryCode
        self.flagEmoji = flagEmoji
        self.prominentTheaters = prominentTheaters
    }
    
    public var toUserLocation: UserLocation {
        UserLocation(
            city: city,
            country: country,
            countryCode: countryCode,
            flagEmoji: flagEmoji,
            isLocal: true,
            area: area,
            isDeviceLocation: false
        )
    }
}

/// Agrupación jerárquica de áreas y ciudades cinematográficas por país
public struct CountryAreaGroup: Identifiable, Sendable, Codable, Equatable, Hashable {
    public var id: String { countryCode }
    public let country: String
    public let countryCode: String
    public let flagEmoji: String
    public let areas: [AreaLocation]
    
    public init(
        country: String,
        countryCode: String,
        flagEmoji: String,
        areas: [AreaLocation]
    ) {
        self.country = country
        self.countryCode = countryCode
        self.flagEmoji = flagEmoji
        self.areas = areas
    }
}
