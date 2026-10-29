import Foundation

/// Representa una sala de proyección física, ciudad y horarios de una película
public struct CinemaShowtime: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let cinemaName: String
    public let city: String
    public let roomFormat: String
    public let times: [String]
    public let bookingURL: URL?
    
    public init(
        id: String = UUID().uuidString,
        cinemaName: String,
        city: String,
        roomFormat: String = "Estándar Digital",
        times: [String] = [],
        bookingURL: URL? = nil
    ) {
        self.id = id
        self.cinemaName = cinemaName
        self.city = city
        self.roomFormat = roomFormat
        self.times = times
        self.bookingURL = bookingURL
    }
}
