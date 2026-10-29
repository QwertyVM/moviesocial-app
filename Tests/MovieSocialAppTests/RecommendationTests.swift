import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Recommendation Engine Tests")
struct RecommendationTests {
    let movieRepo: MovieRepositoryProtocol
    let socialRepo: SocialRepositoryProtocol
    let getRecommendedUseCase: GetRecommendedMoviesUseCase
    let submitReviewUseCase: SubmitReviewUseCase
    
    init() {
        let mRepo = MovieRepositoryImpl()
        let sRepo = SocialRepositoryImpl()
        self.movieRepo = mRepo
        self.socialRepo = sRepo
        self.getRecommendedUseCase = GetRecommendedMoviesUseCase(
            movieRepository: mRepo,
            socialRepository: sRepo
        )
        self.submitReviewUseCase = SubmitReviewUseCase(repository: sRepo)
    }
    
    @Test("Cold start returns empty list for user with zero ratings")
    func testColdStartForNewUser() async throws {
        let result = try await getRecommendedUseCase.execute(userId: "brand_new_user_999")
        #expect(result.movies.isEmpty)
        #expect(result.userRatedCount == 0)
    }
    
    @Test("Recommends matching genre movies and excludes already rated movie")
    func testRecommendationsBasedOnRatings() async throws {
        let testUser = User(
            id: "user_sci_fi_fan",
            email: "fan@movie.com",
            displayName: "SciFi Lover",
            authProvider: .apple
        )
        
        // Rate Dune: Parte Dos with 5.0 stars (Sci-Fi, Aventura)
        _ = try await submitReviewUseCase.execute(
            movieId: "693134",
            movieTitle: "Dune: Parte Dos",
            moviePosterURL: nil,
            movieReleaseYear: 2024,
            rating: 5.0,
            comment: "Increíble película de ciencia ficción",
            user: testUser
        )
        
        let result = try await getRecommendedUseCase.execute(userId: testUser.id)
        
        #expect(!result.movies.isEmpty)
        #expect(result.userRatedCount == 1)
        #expect(result.topGenres.contains("Ciencia Ficción"))
        
        // Excluded: The rated movie must not appear in recommendations
        let recommendedIds = result.movies.map(\.id)
        #expect(!recommendedIds.contains("693134"))
        
        // Included: Interstellar or Alien: Romulus or Spider-Man (Sci-Fi) should be recommended
        let topRecommended = try #require(result.movies.first)
        #expect(topRecommended.genres.contains("Ciencia Ficción") || topRecommended.genres.contains("Aventura"))
        #expect((topRecommended.matchScore ?? 0) >= 80)
        #expect(topRecommended.recommendationReason != nil)
    }
}
