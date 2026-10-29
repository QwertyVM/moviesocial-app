import Foundation

public struct GetMovieDetailUseCase: Sendable {
    private let repository: MovieRepositoryProtocol
    
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(id: String) async throws -> Movie {
        return try await repository.getMovieDetail(id: id)
    }
}

