import Foundation

/// Puntuaciones oficiales externas (Rotten Tomatoes & IMDb)
public struct ExternalRatings: Sendable, Codable, Equatable {
    /// Rotten Tomatoes Tomatometer (Críticos, % de 0 a 100)
    public let rottenTomatoesCritics: Int?
    
    /// Rotten Tomatoes Popcornmeter (Audiencia / Fans, % de 0 a 100)
    public let rottenTomatoesAudience: Int?
    
    /// Puntuación en IMDb (Escala decimal 1.0 - 10.0)
    public let imdbScore: Double?
    
    /// Total de votos en IMDb (ej. "1.8M")
    public let imdbVotes: String?
    
    public init(
        rottenTomatoesCritics: Int? = nil,
        rottenTomatoesAudience: Int? = nil,
        imdbScore: Double? = nil,
        imdbVotes: String? = nil
    ) {
        self.rottenTomatoesCritics = rottenTomatoesCritics
        self.rottenTomatoesAudience = rottenTomatoesAudience
        self.imdbScore = imdbScore
        self.imdbVotes = imdbVotes
    }
    
    public var formattedTomatometer: String? {
        guard let rottenTomatoesCritics else { return nil }
        return "\(rottenTomatoesCritics)%"
    }
    
    public var formattedAudienceScore: String? {
        guard let rottenTomatoesAudience else { return nil }
        return "\(rottenTomatoesAudience)%"
    }
    
    public var formattedIMDb: String? {
        guard let imdbScore else { return nil }
        return String(format: "%.1f", imdbScore)
    }
}

