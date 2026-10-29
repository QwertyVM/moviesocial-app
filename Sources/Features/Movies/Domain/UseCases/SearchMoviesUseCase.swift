import Foundation

public struct SearchMoviesUseCase: Sendable {
    private let repository: MovieRepositoryProtocol
    
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(query: String) async throws -> [Movie] {
        return try await repository.searchMovies(query: query)
    }
}

