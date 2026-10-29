import Foundation

public protocol SocialRepositoryProtocol: Sendable {
    func getFriends() async throws -> [Friend]
    func getFriendsFeed() async throws -> [Review]
    func getReviewsForMovie(movieId: String) async throws -> [Review]
    func addReview(
        movieId: String,
        movieTitle: String,
        moviePosterURL: URL?,
        movieReleaseYear: Int?,
        rating: Double,
        comment: String,
        user: User
    ) async throws -> Review
    func addCommentToReview(
        reviewId: String,
        text: String,
        user: User
    ) async throws -> ReviewComment
    func toggleLikeReview(
        reviewId: String,
        userId: String
    ) async throws -> (isLiked: Bool, newCount: Int)
    func addFriend(username: String) async throws -> Friend
}

