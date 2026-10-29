import Foundation

public protocol SocialRepositoryProtocol: Sendable {
    func getFriends() async throws -> [Friend]
    func getFriendsFeed() async throws -> [Review]
    func getUserReviews(userId: String) async throws -> [Review]
    func getReviewsForMovie(movieId: String) async throws -> [Review]
    func getCommunityReviewsForMovie(movieId: String) async throws -> [Review]
    func addReview(
        movieId: String,
        movieTitle: String,
        moviePosterURL: URL?,
        movieReleaseYear: Int?,
        rating: Double,
        comment: String,
        user: User
    ) async throws -> Review
    func editReview(
        reviewId: String,
        rating: Double,
        comment: String,
        currentDate: Date
    ) async throws -> Review
    func getReviewHistory(
        reviewId: String
    ) async throws -> [ReviewHistoryEntry]
    func addCommentToReview(
        reviewId: String,
        text: String,
        user: User
    ) async throws -> ReviewComment
    func toggleLikeReview(
        reviewId: String,
        userId: String
    ) async throws -> (isLiked: Bool, newCount: Int)
    func toggleHelpfulReview(
        reviewId: String,
        userId: String
    ) async throws -> (isHelpful: Bool, newCount: Int)
    func addFriend(username: String) async throws -> Friend
    func removeFriend(friendId: String) async throws
}

extension SocialRepositoryProtocol {
    public func editReview(
        reviewId: String,
        rating: Double,
        comment: String
    ) async throws -> Review {
        return try await editReview(
            reviewId: reviewId,
            rating: rating,
            comment: comment,
            currentDate: Date()
        )
    }
}
