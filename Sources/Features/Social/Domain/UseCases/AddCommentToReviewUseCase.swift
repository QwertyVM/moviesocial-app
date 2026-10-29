import Foundation

public struct AddCommentToReviewUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(reviewId: String, text: String, user: User) async throws -> ReviewComment {
        try await repository.addCommentToReview(reviewId: reviewId, text: text, user: user)
    }
}
