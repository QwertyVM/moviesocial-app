import Foundation

public struct GetClassicsMoviesUseCase: Sendable {
    private let repository: MovieRepositoryProtocol
    
    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(
        decade: Int? = nil,
        sortByRating: Bool = true,
        page: Int = 1
    ) async throws -> [Movie] {
        return try await repository.getClassics(decade: decade, sortByRating: sortByRating, page: page)
    }
}

