import Foundation

/// Entidad central de Película en el Dominio
public struct Movie: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let title: String
    public let overview: String
    public let releaseYear: Int
    public let releaseDate: String?
    public let posterURL: URL?
    public let backdropURL: URL?
    public let genres: [String]
    public let runtimeMinutes: Int?
    public let imdbId: String?
    public var ratings: ExternalRatings
    public var matchScore: Int?
    public var recommendationReason: String?
    public var isInTheatersLocally: Bool
    public var theatersPlaying: [String]
    public var localShowtimes: [CinemaShowtime]
    public var countryOfOrigin: String?
    
    public init(
        id: String,
        title: String,
        overview: String,
        releaseYear: Int,
        releaseDate: String? = nil,
        posterURL: URL? = nil,
        backdropURL: URL? = nil,
        genres: [String] = [],
        runtimeMinutes: Int? = nil,
        imdbId: String? = nil,
        ratings: ExternalRatings = ExternalRatings(),
        matchScore: Int? = nil,
        recommendationReason: String? = nil,
        isInTheatersLocally: Bool = false,
        theatersPlaying: [String] = [],
        localShowtimes: [CinemaShowtime] = [],
        countryOfOrigin: String? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.releaseYear = releaseYear
        self.releaseDate = releaseDate
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.genres = genres
        self.runtimeMinutes = runtimeMinutes
        self.imdbId = imdbId
        self.ratings = ratings
        self.matchScore = matchScore
        self.recommendationReason = recommendationReason
        self.isInTheatersLocally = isInTheatersLocally
        self.theatersPlaying = theatersPlaying
        self.localShowtimes = localShowtimes
        self.countryOfOrigin = countryOfOrigin
    }
    
    /// Determina si la película pertenece a la cinematografía nacional del país consultado
    public func isNationalCinema(for countryCode: String?) -> Bool {
        guard let countryCode, !countryCode.isEmpty,
              let origin = countryOfOrigin, !origin.isEmpty else {
            return false
        }
        return countryCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == origin.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /// Calcula el estado comercial de exhibición teatral en cines (Estreno Semana 1, 2ª Semana, En Cartelera, etc.)
    public func releaseStatus(referenceDate: Date = Date()) -> TheatricalReleaseStatus {
        guard let releaseDate else {
            return isInTheatersLocally ? .inTheaters : .catalog
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        
        guard let date = formatter.date(from: releaseDate) else {
            return isInTheatersLocally ? .inTheaters : .catalog
        }
        
        let calendar = Calendar.current
        let startOfRef = calendar.startOfDay(for: referenceDate)
        let startOfRelease = calendar.startOfDay(for: date)
        
        let diff = calendar.dateComponents([.day], from: startOfRelease, to: startOfRef).day ?? 0
        
        if diff < 0 {
            return .comingSoon
        } else if diff <= 7 {
            return .premiereWeek
        } else if diff <= 14 {
            return .secondWeek
        } else if isInTheatersLocally || !localShowtimes.isEmpty {
            return .inTheaters
        } else {
            return .catalog
        }
    }
}

/// Estado de la película en el ciclo de exhibición en salas de cine
public enum TheatricalReleaseStatus: String, Codable, Sendable, CaseIterable {
    case premiereWeek = "Estreno"        // Semana 1 (0 a 7 días de estreno)
    case secondWeek = "2ª Semana"       // Semana 2 (8 a 14 días en salas)
    case inTheaters = "En Cartelera"    // Semana 3 en adelante
    case comingSoon = "Próximamente"    // Aún no estrena
    case catalog = "Catálogo"           // Fuera de exhibición activa
    
    public var badgeTitle: String {
        switch self {
        case .premiereWeek: return "ESTRENO"
        case .secondWeek: return "2ª SEMANA"
        case .inTheaters: return "EN CINES"
        case .comingSoon: return "PRÓXIMAMENTE"
        case .catalog: return "CATÁLOGO"
        }
    }
}

public enum MovieCatalogSection: String, CaseIterable, Identifiable, Sendable {
    case recommended = "Para Ti"
    case nowPlaying = "Estrenos"
    case classics = "Clásicos"
    
    public var id: String { rawValue }
}

