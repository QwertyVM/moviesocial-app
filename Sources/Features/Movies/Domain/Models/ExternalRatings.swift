import Foundation

/// Puntuaciones oficiales externas (Rotten Tomatoes & IMDb) con cálculo de cruce ponderado (MovieScore)
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
    
    // MARK: - Cruce Ponderado de Calificaciones (IMDb + Rotten Tomatoes)
    
    /// Puntuación compuesta (Score MovieSocial) normalizada en escala decimal 1.0 - 10.0
    /// Ponderación de referencia acordada:
    /// - 50% IMDb (normalizado 0 a 100)
    /// - 30% Rotten Tomatoes Críticos (0 a 100)
    /// - 20% Rotten Tomatoes Audiencia (0 a 100)
    /// Si falta alguna fuente, el peso se redistribuye proporcionalmente entre las disponibles.
    public var compositeScore: Double? {
        var weightedTotal: Double = 0.0
        var totalWeight: Double = 0.0
        
        if let imdb = imdbScore {
            let normalizedImdb = imdb * 10.0 // escala 10-100
            weightedTotal += normalizedImdb * 0.50
            totalWeight += 0.50
        }
        
        if let critics = rottenTomatoesCritics {
            weightedTotal += Double(critics) * 0.30
            totalWeight += 0.30
        }
        
        if let audience = rottenTomatoesAudience {
            weightedTotal += Double(audience) * 0.20
            totalWeight += 0.20
        }
        
        guard totalWeight > 0.0 else { return nil }
        
        // Puntuación en escala 100 normalizada según peso disponible
        let scoreOn100 = weightedTotal / totalWeight
        // Convertir a escala 1.0 - 10.0 con 1 decimal
        let scoreOn10 = scoreOn100 / 10.0
        return (scoreOn10 * 10.0).rounded() / 10.0
    }
    
    /// Texto formateado del score compuesto (ej. "9.2")
    public var formattedCompositeScore: String? {
        guard let compositeScore else { return nil }
        return String(format: "%.1f", compositeScore)
    }
    
    /// Porcentaje equivalente del score compuesto (ej. 92%)
    public var compositePercentage: Int? {
        guard let compositeScore else { return nil }
        return Int((compositeScore * 10.0).rounded())
    }
}


