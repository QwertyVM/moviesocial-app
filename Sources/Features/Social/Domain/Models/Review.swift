import Foundation

public enum ReviewFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "Todos"
    case friends = "Amigos"
    case local = "Locales"
    case international = "Internacionales"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .all: return "sparkles"
        case .friends: return "person.2.fill"
        case .local: return "mappin.and.ellipse"
        case .international: return "globe.americas.fill"
        }
    }
}

public enum SocialError: LocalizedError, Equatable {
    case reviewAlreadyExists
    case reviewNotFound
    case emptyComment
    case invalidUser
    
    public var errorDescription: String? {
        switch self {
        case .reviewAlreadyExists:
            return "Una persona solo puede publicar una reseña por película. Si deseas modificarla, puedes editar tu reseña existente."
        case .reviewNotFound:
            return "Reseña no encontrada."
        case .emptyComment:
            return "El comentario no puede estar vacío."
        case .invalidUser:
            return "Usuario no válido."
        }
    }
}

public struct ReviewHistoryEntry: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let rating: Double
    public let comment: String
    public let createdAt: Date
    public let archivedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        rating: Double,
        comment: String,
        createdAt: Date,
        archivedAt: Date = Date()
    ) {
        self.id = id
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
    
    public var formattedRating: String {
        String(format: "%.1f", rating)
    }
}

public struct Review: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let userId: String
    public let userName: String
    public let userAvatarURL: URL?
    public let movieId: String
    public let movieTitle: String
    public let moviePosterURL: URL?
    public let movieReleaseYear: Int?
    public var rating: Double // Escala de 1 a 5 (con medios puntos)
    public var comment: String
    public let createdAt: Date
    public var updatedAt: Date?
    public var comments: [ReviewComment]
    public var likesCount: Int
    public var isLikedByMe: Bool
    public var location: UserLocation?
    public var isFriend: Bool
    public var helpfulCount: Int
    public var isHelpfulByMe: Bool
    public var isHistorical: Bool
    public var history: [ReviewHistoryEntry]
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        userName: String,
        userAvatarURL: URL? = nil,
        movieId: String,
        movieTitle: String,
        moviePosterURL: URL? = nil,
        movieReleaseYear: Int? = nil,
        rating: Double,
        comment: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        comments: [ReviewComment] = [],
        likesCount: Int = 0,
        isLikedByMe: Bool = false,
        location: UserLocation? = nil,
        isFriend: Bool = true,
        helpfulCount: Int = 0,
        isHelpfulByMe: Bool = false,
        isHistorical: Bool = false,
        history: [ReviewHistoryEntry] = []
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatarURL = userAvatarURL
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.moviePosterURL = moviePosterURL
        self.movieReleaseYear = movieReleaseYear
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.comments = comments
        self.likesCount = likesCount
        self.isLikedByMe = isLikedByMe
        self.location = location
        self.isFriend = isFriend
        self.helpfulCount = helpfulCount
        self.isHelpfulByMe = isHelpfulByMe
        self.isHistorical = isHistorical
        self.history = history
    }
    
    public var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    public var isEdited: Bool {
        updatedAt != nil
    }
    
    public var hasHistoricalRecord: Bool {
        !history.isEmpty
    }
    
    public var firstReviewHistory: ReviewHistoryEntry? {
        history.first
    }
    
    public var isLocal: Bool {
        location?.isLocal ?? false
    }
    
    public var isInternational: Bool {
        guard let loc = location else { return false }
        return !loc.isLocal
    }
    
    /// Comprueba si han transcurrido más de 3 meses naturales desde la fecha original
    public static func hasPassedMoreThanThreeMonths(from originalDate: Date, to currentDate: Date = Date()) -> Bool {
        let calendar = Calendar.current
        if let threeMonthsLater = calendar.date(byAdding: .month, value: 3, to: originalDate) {
            return currentDate > threeMonthsLater
        }
        return currentDate.timeIntervalSince(originalDate) > (90 * 24 * 3600)
    }
}
