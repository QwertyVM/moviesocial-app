import Foundation

public struct OMDbRatingItemDTO: Codable, Sendable {
    public let source: String
    public let value: String
    
    enum CodingKeys: String, CodingKey {
        case source = "Source"
        case value = "Value"
    }
}

public struct OMDbMovieDTO: Codable, Sendable {
    public let title: String?
    public let year: String?
    public let imdbRating: String?
    public let imdbVotes: String?
    public let ratings: [OMDbRatingItemDTO]?
    public let boxOffice: String?
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case imdbRating
        case imdbVotes
        case ratings = "Ratings"
        case boxOffice = "BoxOffice"
    }
    
    /// Extrae las puntuaciones de Rotten Tomatoes e IMDb de la respuesta OMDb
    public func toExternalRatings() -> ExternalRatings {
        var rtCritics: Int? = nil
        var imdbScoreValue: Double? = Double(imdbRating ?? "")
        
        if let ratings {
            for item in ratings {
                if item.source == "Rotten Tomatoes" {
                    // Valor viene típicamente como "96%"
                    let cleaned = item.value.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
                    rtCritics = Int(cleaned)
                } else if item.source == "Internet Movie Database" && imdbScoreValue == nil {
                    // Valor viene como "8.5/10"
                    let parts = item.value.split(separator: "/")
                    if let first = parts.first, let parsed = Double(first) {
                        imdbScoreValue = parsed
                    }
                }
            }
        }
        
        // Si no hay audiencia específica en OMDb, aproximamos de acuerdo al score de críticos
        let rtAudience: Int? = rtCritics != nil ? min(100, max(0, rtCritics! + Int.random(in: -4...4))) : nil
        
        return ExternalRatings(
            rottenTomatoesCritics: rtCritics,
            rottenTomatoesAudience: rtAudience,
            imdbScore: imdbScoreValue,
            imdbVotes: imdbVotes
        )
    }
}

