import Foundation

public struct GetNowPlayingMoviesUseCase: Sendable {
    private let repository: MovieRepositoryProtocol
    
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(
        city: String? = nil,
        countryCode: String? = nil,
        page: Int = 1
    ) async throws -> [Movie] {
        return try await repository.getNowPlaying(city: city, countryCode: countryCode, page: page)
    }
}

