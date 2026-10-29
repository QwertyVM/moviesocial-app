import Foundation

public struct ToggleHelpfulReviewUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(reviewId: String, userId: String) async throws -> (isHelpful: Bool, newCount: Int) {
        return try await repository.toggleHelpfulReview(reviewId: reviewId, userId: userId)
    }
}
