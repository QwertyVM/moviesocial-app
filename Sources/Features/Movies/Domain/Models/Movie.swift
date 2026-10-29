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
        ratings: ExternalRatings = ExternalRatings()
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
    }
}

public enum MovieCatalogSection: String, CaseIterable, Identifiable, Sendable {
    case nowPlaying = "Estrenos"
    case classics = "Clásicos"
    
    public var id: String { rawValue }
}

