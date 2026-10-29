import Foundation

public protocol MovieRepositoryProtocol: Sendable {
    func getNowPlaying(city: String?, countryCode: String?, page: Int) async throws -> [Movie]
    func getClassics(decade: Int?, sortByRating: Bool, page: Int) async throws -> [Movie]
    func searchMovies(query: String) async throws -> [Movie]
    func getMovieDetail(id: String) async throws -> Movie
    func getAllMovies() async throws -> [Movie]
    func getAvailableCities() -> [UserLocation]
}

public extension MovieRepositoryProtocol {
    func getNowPlaying(page: Int = 1) async throws -> [Movie] {
        try await getNowPlaying(city: nil, countryCode: nil, page: page)
    }
    
    func getClassics(page: Int = 1) async throws -> [Movie] {
        try await getClassics(decade: nil, sortByRating: true, page: page)
    }
    
    func getAvailableCities() -> [UserLocation] {
        return []
    }
}


