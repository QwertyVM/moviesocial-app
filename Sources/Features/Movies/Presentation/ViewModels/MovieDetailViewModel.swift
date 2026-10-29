import Foundation
import Observation

@Observable
public final class MovieDetailViewModel: @unchecked Sendable {
    public var movie: Movie
    public var friendReviews: [Review] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var isPresentingAddReview: Bool = false
    public var selectedReviewForComments: Review?
    
    private let getMovieDetailUseCase: GetMovieDetailUseCase
    private let getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase
    private let submitReviewUseCase: SubmitReviewUseCase
    private let addCommentToReviewUseCase: AddCommentToReviewUseCase
    private let toggleLikeReviewUseCase: ToggleLikeReviewUseCase
    
    public init(
        movie: Movie,
        getMovieDetailUseCase: GetMovieDetailUseCase,
        getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase,
        submitReviewUseCase: SubmitReviewUseCase,
        addCommentToReviewUseCase: AddCommentToReviewUseCase? = nil,
        toggleLikeReviewUseCase: ToggleLikeReviewUseCase? = nil
    ) {
        self.movie = movie
        self.getMovieDetailUseCase = getMovieDetailUseCase
        self.getFriendsReviewsUseCase = getFriendsReviewsUseCase
        self.submitReviewUseCase = submitReviewUseCase
        self.addCommentToReviewUseCase = addCommentToReviewUseCase ?? AddCommentToReviewUseCase(repository: SocialRepositoryImpl())
        self.toggleLikeReviewUseCase = toggleLikeReviewUseCase ?? ToggleLikeReviewUseCase(repository: SocialRepositoryImpl())
    }
    
    public var friendsAverageRating: Double? {
        guard !friendReviews.isEmpty else { return nil }
        let sum = friendReviews.reduce(0.0) { $0 + $1.rating }
        return sum / Double(friendReviews.count)
    }
    
    @MainActor
    public func loadDetails() async {
        isLoading = true
        errorMessage = nil
        do {
            async let updatedMovie = getMovieDetailUseCase.execute(id: movie.id)
            async let reviews = getFriendsReviewsUseCase.execute(movieId: movie.id)
            
            self.movie = try await updatedMovie
            self.friendReviews = try await reviews
            
            if let selectedId = selectedReviewForComments?.id {
                self.selectedReviewForComments = self.friendReviews.first(where: { $0.id == selectedId })
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func submitReview(rating: Double, comment: String, currentUser: User) async -> Bool {
        do {
            let newReview = try await submitReviewUseCase.execute(
                movieId: movie.id,
                movieTitle: movie.title,
                moviePosterURL: movie.posterURL,
                movieReleaseYear: movie.releaseYear,
                rating: rating,
                comment: comment,
                user: currentUser
            )
            self.friendReviews.insert(newReview, at: 0)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func toggleLike(reviewId: String, user: User) async {
        do {
            let result = try await toggleLikeReviewUseCase.execute(reviewId: reviewId, userId: user.id)
            if let index = friendReviews.firstIndex(where: { $0.id == reviewId }) {
                friendReviews[index].isLikedByMe = result.isLiked
                friendReviews[index].likesCount = result.newCount
                if selectedReviewForComments?.id == reviewId {
                    selectedReviewForComments = friendReviews[index]
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func addComment(to reviewId: String, text: String, user: User) async -> Bool {
        do {
            let newComment = try await addCommentToReviewUseCase.execute(reviewId: reviewId, text: text, user: user)
            if let index = friendReviews.firstIndex(where: { $0.id == reviewId }) {
                friendReviews[index].comments.append(newComment)
                if selectedReviewForComments?.id == reviewId {
                    selectedReviewForComments = friendReviews[index]
                }
            }
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
}
