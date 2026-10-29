import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Social Use Cases Tests")
struct SocialUseCasesTests {
    let socialRepo: SocialRepositoryProtocol
    let getActivityUseCase: GetFriendsActivityUseCase
    let submitReviewUseCase: SubmitReviewUseCase
    let addFriendUseCase: AddFriendUseCase
    let addCommentUseCase: AddCommentToReviewUseCase
    let toggleLikeUseCase: ToggleLikeReviewUseCase
    
    init() {
        let repo = SocialRepositoryImpl()
        self.socialRepo = repo
        self.getActivityUseCase = GetFriendsActivityUseCase(repository: repo)
        self.submitReviewUseCase = SubmitReviewUseCase(repository: repo)
        self.addFriendUseCase = AddFriendUseCase(repository: repo)
        self.addCommentUseCase = AddCommentToReviewUseCase(repository: repo)
        self.toggleLikeUseCase = ToggleLikeReviewUseCase(repository: repo)
    }
    
    @Test("Get Friends Feed Returns Activity")
    func getFriendsFeedReturnsActivity() async throws {
        let feed = try await getActivityUseCase.execute()
        #expect(!feed.isEmpty)
        #expect(feed.first?.movieTitle == "Dune: Parte Dos")
    }
    
    @Test("Submit Review Adds New Review To Top")
    func submitReviewAddsNewReviewToTop() async throws {
        let testUser = User(
            id: "user_test",
            email: "test@apple.com",
            displayName: "Test Reviewer",
            authProvider: .apple
        )
        
        let newReview = try await submitReviewUseCase.execute(
            movieId: "129",
            movieTitle: "El Viaje de Chihiro",
            moviePosterURL: nil,
            movieReleaseYear: 2001,
            rating: 5.0,
            comment: "Una obra de arte absoluta.",
            user: testUser
        )
        
        #expect(newReview.movieTitle == "El Viaje de Chihiro")
        #expect(newReview.rating == 5.0)
        #expect(newReview.userName == "Test Reviewer")
        
        // Feed must contain it now
        let feed = try await getActivityUseCase.execute()
        #expect(feed.first?.id == newReview.id)
    }
    
    @Test("Add Friend")
    func addFriend() async throws {
        let newFriend = try await addFriendUseCase.execute(username: "@directora_cine")
        #expect(newFriend.username == "@directora_cine")
        
        let friends = try await socialRepo.getFriends()
        #expect(friends.contains(where: { $0.id == newFriend.id }))
    }
    
    @Test("Add Comment To Friend Review")
    func addCommentToFriendReview() async throws {
        let testUser = User(
            id: "user_cinefilo",
            email: "cine@movie.com",
            displayName: "Cinéfilo Experto",
            authProvider: .apple
        )
        
        let comment = try await addCommentUseCase.execute(
            reviewId: "rev_1",
            text: "¡La banda sonora de Hans Zimmer es impresionante!",
            user: testUser
        )
        
        #expect(comment.reviewId == "rev_1")
        #expect(comment.userName == "Cinéfilo Experto")
        #expect(comment.text == "¡La banda sonora de Hans Zimmer es impresionante!")
        
        let feed = try await getActivityUseCase.execute()
        let updatedReview = feed.first(where: { $0.id == "rev_1" })
        #expect(updatedReview?.comments.contains(where: { $0.id == comment.id }) == true)
    }
    
    @Test("Toggle Like On Friend Review")
    func toggleLikeOnFriendReview() async throws {
        let initialFeed = try await getActivityUseCase.execute()
        let review = try #require(initialFeed.first(where: { $0.id == "rev_1" }))
        let initialLikes = review.likesCount
        
        let toggleResult = try await toggleLikeUseCase.execute(reviewId: "rev_1", userId: "user_test")
        #expect(toggleResult.newCount != initialLikes)
    }
}
