import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Community Reviews & Paywall Tests")
struct CommunityReviewsAndPaywallTests {
    let socialRepo: SocialRepositoryProtocol
    let getCommunityReviewsUseCase: GetCommunityReviewsUseCase
    let toggleHelpfulUseCase: ToggleHelpfulReviewUseCase
    let addFriendUseCase: AddFriendUseCase
    
    init() {
        let repo = SocialRepositoryImpl()
        self.socialRepo = repo
        self.getCommunityReviewsUseCase = GetCommunityReviewsUseCase(repository: repo)
        self.toggleHelpfulUseCase = ToggleHelpfulReviewUseCase(repository: repo)
        self.addFriendUseCase = AddFriendUseCase(repository: repo)
    }
    
    @Test("Community Reviews Include Local and International Non-Friend Opinions")
    func communityReviewsIncludeLocalAndInternational() async throws {
        let reviews = try await getCommunityReviewsUseCase.execute(movieId: "693134") // Dune: Parte Dos
        
        #expect(!reviews.isEmpty)
        
        // Debe contener reseñas de personas que NO están en la lista de amigos
        let nonFriendReviews = reviews.filter { !$0.isFriend }
        #expect(!nonFriendReviews.isEmpty)
        
        // Debe contener opiniones locales (ej. Madrid, Barcelona)
        let localReviews = reviews.filter { $0.isLocal }
        #expect(!localReviews.isEmpty)
        #expect(localReviews.contains(where: { $0.location?.city == "Madrid" }))
        
        // Debe contener opiniones internacionales (ej. Tokio, Nueva York, París)
        let internationalReviews = reviews.filter { $0.isInternational }
        #expect(!internationalReviews.isEmpty)
        #expect(internationalReviews.contains(where: { $0.location?.country == "Japón" }))
        #expect(internationalReviews.contains(where: { $0.location?.country == "EE. UU." }))
    }
    
    @Test("Toggle Helpful Vote on Non-Friend Review")
    func toggleHelpfulVoteOnCommunityReview() async throws {
        let reviews = try await getCommunityReviewsUseCase.execute(movieId: "693134")
        let nonFriendReview = try #require(reviews.first(where: { !$0.isFriend }))
        let initialHelpfulCount = nonFriendReview.helpfulCount
        
        // Votar como útil
        let (isHelpful, newCount) = try await toggleHelpfulUseCase.execute(
            reviewId: nonFriendReview.id,
            userId: "user_tester"
        )
        
        #expect(isHelpful == true)
        #expect(newCount == initialHelpfulCount + 1)
        
        // Des-votar
        let (isHelpfulAgain, revertedCount) = try await toggleHelpfulUseCase.execute(
            reviewId: nonFriendReview.id,
            userId: "user_tester"
        )
        
        #expect(isHelpfulAgain == false)
        #expect(revertedCount == initialHelpfulCount)
    }
    
    @Test("Add Non-Friend Reviewer As Friend From Review")
    func addNonFriendReviewerAsFriend() async throws {
        let reviews = try await getCommunityReviewsUseCase.execute(movieId: "693134")
        let nonFriendReview = try #require(reviews.first(where: { !$0.isFriend }))
        
        let newFriend = try await addFriendUseCase.execute(username: nonFriendReview.userName)
        #expect(newFriend.displayName.lowercased() == nonFriendReview.userName.lowercased())
        
        let friendsList = try await socialRepo.getFriends()
        #expect(friendsList.contains(where: { $0.id == newFriend.id }))
    }
    
    @Test("MovieDetailViewModel Unlocks Global Reviews with Subscription")
    @MainActor
    func movieDetailViewModelUnlocksWithSubscription() async throws {
        let movie = Movie(
            id: "693134",
            title: "Dune: Parte Dos",
            overview: "Paul Atreides se une a Chani y a los Fremen.",
            releaseYear: 2024
        )
        
        let freeUser = User(
            id: "user_free",
            email: "free@movie.com",
            displayName: "Usuario Gratis",
            authProvider: .apple,
            isPremium: false
        )
        
        let viewModel = MovieDetailViewModel(
            movie: movie,
            getMovieDetailUseCase: GetMovieDetailUseCase(repository: MovieRepositoryImpl()),
            getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase(repository: socialRepo),
            getCommunityReviewsUseCase: getCommunityReviewsUseCase,
            submitReviewUseCase: SubmitReviewUseCase(repository: socialRepo),
            isSubscribed: false
        )
        
        await viewModel.loadDetails(currentUser: freeUser)
        
        // Usuario gratuito sin suscripción no tiene el pase activo
        #expect(viewModel.isSubscribed == false)
        #expect(viewModel.displayedReviews.count == viewModel.friendReviews.count)
        
        // Usuario adquiere la suscripción / pase de paga
        viewModel.subscribeUser()
        
        #expect(viewModel.isSubscribed == true)
        #expect(viewModel.displayedReviews.count > viewModel.friendReviews.count)
        
        // Filtrar por reseñas locales
        viewModel.selectedFilter = .local
        #expect(viewModel.displayedReviews.allSatisfy { $0.isLocal })
        
        // Filtrar por reseñas internacionales
        viewModel.selectedFilter = .international
        #expect(viewModel.displayedReviews.allSatisfy { $0.isInternational })
    }
    
    @Test("Dynamic Generator Creates Community Reviews For Uncached Movie")
    func dynamicGeneratorCreatesCommunityReviews() async throws {
        let uncachedMovieId = "arbitrary_movie_9999"
        let reviews = try await getCommunityReviewsUseCase.execute(movieId: uncachedMovieId)
        
        #expect(!reviews.isEmpty)
        #expect(reviews.contains(where: { $0.isLocal }))
        #expect(reviews.contains(where: { $0.isInternational }))
    }
}
