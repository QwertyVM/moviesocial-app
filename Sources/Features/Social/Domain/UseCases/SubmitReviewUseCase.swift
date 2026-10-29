import Foundation

public struct SubmitReviewUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(
        movieId: String,
        movieTitle: String,
        moviePosterURL: URL?,
        movieReleaseYear: Int?,
        rating: Double,
        comment: String,
        user: User
    ) async throws -> Review {
        return try await repository.addReview(
            movieId: movieId,
            movieTitle: movieTitle,
            moviePosterURL: moviePosterURL,
            movieReleaseYear: movieReleaseYear,
            rating: rating,
            comment: comment,
            user: user
        )
    }
}

