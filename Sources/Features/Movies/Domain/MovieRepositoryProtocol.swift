import Foundation

public protocol MovieRepositoryProtocol: Sendable {
    func getNowPlaying(page: Int) async throws -> [Movie]
    func getClassics(page: Int) async throws -> [Movie]
    func searchMovies(query: String) async throws -> [Movie]
    func getMovieDetail(id: String) async throws -> Movie
}

