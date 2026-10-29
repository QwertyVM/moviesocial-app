import Foundation

public struct GetFriendsReviewsForMovieUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(movieId: String) async throws -> [Review] {
        return try await repository.getReviewsForMovie(movieId: movieId)
    }
}

