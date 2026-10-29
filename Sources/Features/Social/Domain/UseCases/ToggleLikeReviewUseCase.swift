import Foundation

public struct ToggleLikeReviewUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(reviewId: String, userId: String) async throws -> (isLiked: Bool, newCount: Int) {
        try await repository.toggleLikeReview(reviewId: reviewId, userId: userId)
    }
}
