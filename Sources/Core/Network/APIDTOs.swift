import Foundation

// MARK: - DTOs de Solicitudes y Respuestas para la API REST

public struct CreateReviewRequest: Encodable, Sendable {
    public let id: String
    public let movieId: String
    public let movieTitle: String
    public let moviePosterURL: String?
    public let movieReleaseYear: Int?
    public let userId: String
    public let userName: String
    public let rating: Double
    public let comment: String
    public let isCommunity: Bool
    
    public init(id: String, movieId: String, movieTitle: String, moviePosterURL: String?, movieReleaseYear: Int?, userId: String, userName: String, rating: Double, comment: String, isCommunity: Bool) {
        self.id = id
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.moviePosterURL = moviePosterURL
        self.movieReleaseYear = movieReleaseYear
        self.userId = userId
        self.userName = userName
        self.rating = rating
        self.comment = comment
        self.isCommunity = isCommunity
    }
}

public struct UpdateReviewRequest: Encodable, Sendable {
    public let rating: Double?
    public let comment: String?
    
    public init(rating: Double? = nil, comment: String? = nil) {
        self.rating = rating
        self.comment = comment
    }
}

public struct CreateFriendRequest: Encodable, Sendable {
    public let id: String
    public let displayName: String
    public let username: String
    public let avatarURL: String?
    
    public init(id: String, displayName: String, username: String, avatarURL: String?) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
    }
}

public struct CreateGroupRequest: Encodable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let iconEmoji: String
    public let creatorId: String
    public let creatorName: String
    public let inviteCode: String
    
    public init(id: String, name: String, description: String, iconEmoji: String, creatorId: String, creatorName: String, inviteCode: String) {
        self.id = id
        self.name = name
        self.description = description
        self.iconEmoji = iconEmoji
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.inviteCode = inviteCode
    }
}

public struct SendGroupMessageRequest: Encodable, Sendable {
    public let id: String
    public let userId: String
    public let userName: String
    public let text: String
    public let messageType: String
    public let sharedMovieId: String?
    public let sharedMovieTitle: String?
    
    public init(id: String, userId: String, userName: String, text: String, messageType: String, sharedMovieId: String?, sharedMovieTitle: String?) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.text = text
        self.messageType = messageType
        self.sharedMovieId = sharedMovieId
        self.sharedMovieTitle = sharedMovieTitle
    }
}

public struct UpdateUserRequest: Encodable, Sendable {
    public let displayName: String?
    public let username: String?
    public let bio: String?
    public let city: String?
    public let country: String?
    
    public init(displayName: String? = nil, username: String? = nil, bio: String? = nil, city: String? = nil, country: String? = nil) {
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.city = city
        self.country = country
    }
}

// MARK: - DTOs para Cartelera y Horarios de Cines desde Neon DB

public struct CinemaShowtimeDTO: Codable, Sendable {
    public let id: String
    public let movieId: String
    public let cinemaChain: String
    public let cinemaName: String
    public let city: String
    public let countryCode: String
    public let address: String?
    public let screenType: String
    public let languageVersion: String
    public let showtimes: String
    public let ticketBookingUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case movieId = "movie_id"
        case cinemaChain = "cinema_chain"
        case cinemaName = "cinema_name"
        case city
        case countryCode = "country_code"
        case address
        case screenType = "screen_type"
        case languageVersion = "language_version"
        case showtimes
        case ticketBookingUrl = "ticket_booking_url"
    }
    
    /// Convierte el string JSON de horarios a un array de strings ["16:30", "19:15"]
    public var parsedTimes: [String] {
        guard let data = showtimes.data(using: .utf8),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            return [showtimes]
        }
        return list
    }
}

public struct TheatricalMovieDTO: Codable, Sendable {
    public let id: String
    public let title: String
    public let synopsis: String?
    public let posterUrl: String
    public let backdropUrl: String?
    public let releaseDate: String
    public let originCountry: String
    public let originCountryName: String?
    public let genres: String?
    public let director: String?
    public let castMembers: String?
    public let durationMinutes: Int?
    public let ageRating: String?
    public let rottenCritics: Int?
    public let rottenAudience: Int?
    public let imdbRating: String?
    public let compositeScore: String?
    public let showtimes: [CinemaShowtimeDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, synopsis
        case posterUrl = "poster_url"
        case backdropUrl = "backdrop_url"
        case releaseDate = "release_date"
        case originCountry = "origin_country"
        case originCountryName = "origin_country_name"
        case genres, director
        case castMembers = "cast_members"
        case durationMinutes = "duration_minutes"
        case ageRating = "age_rating"
        case rottenCritics = "rotten_critics"
        case rottenAudience = "rotten_audience"
        case imdbRating = "imdb_rating"
        case compositeScore = "composite_score"
        case showtimes
    }
}

extension TheatricalMovieDTO {
    public func toDomain() -> Movie {
        let year: Int = {
            if let first4 = releaseDate.split(separator: "-").first, let y = Int(first4) {
                return y
            }
            return 2026
        }()
        
        let splitGenres = genres?.split(separator: "•").map { $0.trimmingCharacters(in: .whitespaces) } ?? ["Cine"]
        let imdbDouble = imdbRating.flatMap { Double($0) } ?? 8.0
        let critics = rottenCritics ?? 85
        let audience = rottenAudience ?? 88
        let ratings = ExternalRatings(
            rottenTomatoesCritics: critics,
            rottenTomatoesAudience: audience,
            imdbScore: imdbDouble,
            imdbVotes: "150K"
        )
        
        let parsedLocalShowtimes: [CinemaShowtime] = (showtimes ?? []).map { dto in
            CinemaShowtime(
                cinemaName: dto.cinemaName,
                city: dto.city,
                roomFormat: "\(dto.screenType) • \(dto.languageVersion)",
                times: dto.parsedTimes
            )
        }
        
        let isLoc = !parsedLocalShowtimes.isEmpty
        let theaters = Array(Set(parsedLocalShowtimes.map(\.cinemaName))).sorted()
        
        return Movie(
            id: id,
            title: title,
            overview: synopsis ?? "",
            releaseYear: year,
            releaseDate: releaseDate,
            posterURL: URL(string: posterUrl),
            backdropURL: backdropUrl.flatMap { URL(string: $0) },
            genres: splitGenres,
            runtimeMinutes: durationMinutes ?? 120,
            imdbId: id,
            ratings: ratings,
            matchScore: 95,
            recommendationReason: "Estreno en Cartelera",
            isInTheatersLocally: isLoc,
            theatersPlaying: theaters,
            localShowtimes: parsedLocalShowtimes,
            countryOfOrigin: originCountry
        )
    }
}


public struct GenericAPIResponse: Decodable, Sendable {
    public let message: String?
    public let id: String?
    public let error: String?
}

public struct ServerHealthResponse: Decodable, Sendable {
    public let status: String
    public let database: String
    public let server: String
    public let version: String
    public let stats: [String: Int]?
}
