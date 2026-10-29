import Foundation

public struct EditReviewUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(
        reviewId: String,
        rating: Double,
        comment: String,
        currentDate: Date = Date()
    ) async throws -> Review {
        return try await repository.editReview(
            reviewId: reviewId,
            rating: rating,
            comment: comment,
            currentDate: currentDate
        )
    }
}
