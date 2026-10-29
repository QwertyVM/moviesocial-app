import Foundation

public struct GetCommunityReviewsUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(movieId: String) async throws -> [Review] {
        return try await repository.getCommunityReviewsForMovie(movieId: movieId)
    }
}
