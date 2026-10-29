import Foundation
import Observation

@Observable
public final class MovieDetailViewModel: @unchecked Sendable {
    public var movie: Movie
    public var friendReviews: [Review] = []
    public var communityReviews: [Review] = []
    public var selectedFilter: ReviewFilter = .all
    public var isSubscribed: Bool = false
    public var isPresentingPaywall: Bool = false
    public var isPresentingAddReview: Bool = false
    public var selectedReviewForComments: Review?
    public var addedFriendUsernames: Set<String> = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    private let getMovieDetailUseCase: GetMovieDetailUseCase
    private let getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase
    private let getCommunityReviewsUseCase: GetCommunityReviewsUseCase
    private let submitReviewUseCase: SubmitReviewUseCase
    private let editReviewUseCase: EditReviewUseCase
    private let addCommentToReviewUseCase: AddCommentToReviewUseCase
    private let toggleLikeReviewUseCase: ToggleLikeReviewUseCase
    private let toggleHelpfulReviewUseCase: ToggleHelpfulReviewUseCase
    private let addFriendUseCase: AddFriendUseCase
    
    public init(
        movie: Movie,
        getMovieDetailUseCase: GetMovieDetailUseCase,
        getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase,
        getCommunityReviewsUseCase: GetCommunityReviewsUseCase? = nil,
        submitReviewUseCase: SubmitReviewUseCase,
        editReviewUseCase: EditReviewUseCase? = nil,
        addCommentToReviewUseCase: AddCommentToReviewUseCase? = nil,
        toggleLikeReviewUseCase: ToggleLikeReviewUseCase? = nil,
        toggleHelpfulReviewUseCase: ToggleHelpfulReviewUseCase? = nil,
        addFriendUseCase: AddFriendUseCase? = nil,
        isSubscribed: Bool = false
    ) {
        self.movie = movie
        self.getMovieDetailUseCase = getMovieDetailUseCase
        self.getFriendsReviewsUseCase = getFriendsReviewsUseCase
        self.getCommunityReviewsUseCase = getCommunityReviewsUseCase ?? GetCommunityReviewsUseCase(repository: SocialRepositoryImpl())
        self.submitReviewUseCase = submitReviewUseCase
        self.editReviewUseCase = editReviewUseCase ?? EditReviewUseCase(repository: SocialRepositoryImpl())
        self.addCommentToReviewUseCase = addCommentToReviewUseCase ?? AddCommentToReviewUseCase(repository: SocialRepositoryImpl())
        self.toggleLikeReviewUseCase = toggleLikeReviewUseCase ?? ToggleLikeReviewUseCase(repository: SocialRepositoryImpl())
        self.toggleHelpfulReviewUseCase = toggleHelpfulReviewUseCase ?? ToggleHelpfulReviewUseCase(repository: SocialRepositoryImpl())
        self.addFriendUseCase = addFriendUseCase ?? AddFriendUseCase(repository: SocialRepositoryImpl())
        self.isSubscribed = isSubscribed
    }
    
    // MARK: - Computed Properties
    
    public var friendsAverageRating: Double? {
        guard !friendReviews.isEmpty else { return nil }
        let sum = friendReviews.reduce(0.0) { $0 + $1.rating }
        return sum / Double(friendReviews.count)
    }
    
    public var localReviews: [Review] {
        communityReviews.filter { $0.isLocal }
    }
    
    public var internationalReviews: [Review] {
        communityReviews.filter { $0.isInternational }
    }
    
    public var localAverageRating: Double? {
        guard !localReviews.isEmpty else { return nil }
        let sum = localReviews.reduce(0.0) { $0 + $1.rating }
        return sum / Double(localReviews.count)
    }
    
    public var internationalAverageRating: Double? {
        guard !internationalReviews.isEmpty else { return nil }
        let sum = internationalReviews.reduce(0.0) { $0 + $1.rating }
        return sum / Double(internationalReviews.count)
    }
    
    public var displayedReviews: [Review] {
        switch selectedFilter {
        case .all:
            return isSubscribed ? communityReviews : friendReviews
        case .friends:
            return friendReviews
        case .local:
            return localReviews
        case .international:
            return internationalReviews
        }
    }
    
    public func userReview(userId: String?) -> Review? {
        guard let userId = userId else { return nil }
        return friendReviews.first(where: { $0.userId == userId && !$0.isHistorical })
            ?? communityReviews.first(where: { $0.userId == userId && !$0.isHistorical })
    }
    
    // MARK: - Actions
    
    @MainActor
    public func loadDetails(currentUser: User? = nil) async {
        if let currentUser {
            self.isSubscribed = currentUser.isPremium
        }
        
        isLoading = true
        errorMessage = nil
        do {
            async let updatedMovie = getMovieDetailUseCase.execute(id: movie.id)
            async let friendRevs = getFriendsReviewsUseCase.execute(movieId: movie.id)
            async let commRevs = getCommunityReviewsUseCase.execute(movieId: movie.id)
            
            self.movie = try await updatedMovie
            self.friendReviews = try await friendRevs
            self.communityReviews = try await commRevs
            
            if let selectedId = selectedReviewForComments?.id {
                self.selectedReviewForComments = self.communityReviews.first(where: { $0.id == selectedId })
                    ?? self.friendReviews.first(where: { $0.id == selectedId })
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func subscribeUser() {
        self.isSubscribed = true
        self.isPresentingPaywall = false
    }
    
    @MainActor
    public func submitReview(rating: Double, comment: String, currentUser: User) async -> Bool {
        // Regla: si el usuario ya tiene una reseña previa para esta película, se edita
        if let existing = userReview(userId: currentUser.id) {
            return await editReview(reviewId: existing.id, rating: rating, comment: comment)
        }
        
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
            self.communityReviews.insert(newReview, at: 0)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func editReview(
        reviewId: String,
        rating: Double,
        comment: String,
        currentDate: Date = Date()
    ) async -> Bool {
        do {
            let updated = try await editReviewUseCase.execute(
                reviewId: reviewId,
                rating: rating,
                comment: comment,
                currentDate: currentDate
            )
            if let idx = friendReviews.firstIndex(where: { $0.id == reviewId }) {
                friendReviews[idx] = updated
            }
            if let idx = communityReviews.firstIndex(where: { $0.id == reviewId }) {
                communityReviews[idx] = updated
            }
            if selectedReviewForComments?.id == reviewId {
                selectedReviewForComments = updated
            }
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
            }
            if let index = communityReviews.firstIndex(where: { $0.id == reviewId }) {
                communityReviews[index].isLikedByMe = result.isLiked
                communityReviews[index].likesCount = result.newCount
            }
            
            if selectedReviewForComments?.id == reviewId {
                selectedReviewForComments = communityReviews.first(where: { $0.id == reviewId })
                    ?? friendReviews.first(where: { $0.id == reviewId })
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func toggleHelpful(reviewId: String, user: User) async {
        do {
            let result = try await toggleHelpfulReviewUseCase.execute(reviewId: reviewId, userId: user.id)
            
            if let index = communityReviews.firstIndex(where: { $0.id == reviewId }) {
                communityReviews[index].isHelpfulByMe = result.isHelpful
                communityReviews[index].helpfulCount = result.newCount
            }
            if let index = friendReviews.firstIndex(where: { $0.id == reviewId }) {
                friendReviews[index].isHelpfulByMe = result.isHelpful
                friendReviews[index].helpfulCount = result.newCount
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func addFriendFromReview(userName: String) async -> Bool {
        do {
            _ = try await addFriendUseCase.execute(username: userName)
            self.addedFriendUsernames.insert(userName)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func addComment(to reviewId: String, text: String, user: User) async -> Bool {
        do {
            let newComment = try await addCommentToReviewUseCase.execute(reviewId: reviewId, text: text, user: user)
            
            if let index = friendReviews.firstIndex(where: { $0.id == reviewId }) {
                friendReviews[index].comments.append(newComment)
            }
            if let index = communityReviews.firstIndex(where: { $0.id == reviewId }) {
                communityReviews[index].comments.append(newComment)
            }
            
            if selectedReviewForComments?.id == reviewId {
                selectedReviewForComments = communityReviews.first(where: { $0.id == reviewId })
                    ?? friendReviews.first(where: { $0.id == reviewId })
            }
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
}
