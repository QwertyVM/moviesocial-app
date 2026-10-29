import Testing
@testable import MovieSocialApp

@Suite("Composite Rating Engine (IMDb + Rotten Tomatoes) Tests")
struct CompositeRatingTests {
    
    @Test("Calculates correct composite score when all ratings are present")
    func testAllRatingsPresent() {
        // IMDb 9.0 (norm: 90.0), RT Critics 90%, RT Audience 90%
        // Total = (90 * 0.50) + (90 * 0.30) + (90 * 0.20) = 45 + 27 + 18 = 90.0 / 10.0 = 9.0
        let ratings = ExternalRatings(
            rottenTomatoesCritics: 90,
            rottenTomatoesAudience: 90,
            imdbScore: 9.0,
            imdbVotes: "1.0M"
        )
        
        #expect(ratings.compositeScore == 9.0)
        #expect(ratings.formattedCompositeScore == "9.0")
        #expect(ratings.compositePercentage == 90)
    }
    
    @Test("Calculates composite score for The Godfather accurately")
    func testTheGodfatherRatingBlend() {
        // The Godfather: IMDb 9.2 (92.0), Critics 97%, Audience 98%
        // Weighted = (92.0 * 0.50) + (97.0 * 0.30) + (98.0 * 0.20)
        // = 46.0 + 29.1 + 19.6 = 94.7 -> 9.5
        let godfatherRatings = ExternalRatings(
            rottenTomatoesCritics: 97,
            rottenTomatoesAudience: 98,
            imdbScore: 9.2,
            imdbVotes: "2.0M"
        )
        
        #expect(godfatherRatings.compositeScore == 9.5)
        #expect(godfatherRatings.formattedCompositeScore == "9.5")
        #expect(godfatherRatings.compositePercentage == 95)
    }
    
    @Test("Handles missing Rotten Tomatoes Audience gracefully by redistributing weight")
    func testMissingAudienceRating() {
        // IMDb 8.0 (80.0), RT Critics 100%
        // Weight sum = 0.50 + 0.30 = 0.80
        // Weighted sum = (80.0 * 0.50) + (100.0 * 0.30) = 40.0 + 30.0 = 70.0
        // Score on 100 = 70.0 / 0.80 = 87.5 -> 8.8
        let ratings = ExternalRatings(
            rottenTomatoesCritics: 100,
            rottenTomatoesAudience: nil,
            imdbScore: 8.0
        )
        
        #expect(ratings.compositeScore == 8.8)
        #expect(ratings.formattedCompositeScore == "8.8")
    }
    
    @Test("Handles movie with only IMDb score")
    func testOnlyIMDbPresent() {
        let ratings = ExternalRatings(
            rottenTomatoesCritics: nil,
            rottenTomatoesAudience: nil,
            imdbScore: 8.4
        )
        
        #expect(ratings.compositeScore == 8.4)
        #expect(ratings.formattedCompositeScore == "8.4")
        #expect(ratings.compositePercentage == 84)
    }
    
    @Test("Handles movie with only Rotten Tomatoes present")
    func testOnlyRottenTomatoesPresent() {
        // Critics 90%, Audience 80%
        // Weight sum = 0.30 + 0.20 = 0.50
        // Weighted sum = (90 * 0.30) + (80 * 0.20) = 27.0 + 16.0 = 43.0
        // Score on 100 = 43.0 / 0.50 = 86.0 -> 8.6
        let ratings = ExternalRatings(
            rottenTomatoesCritics: 90,
            rottenTomatoesAudience: 80,
            imdbScore: nil
        )
        
        #expect(ratings.compositeScore == 8.6)
        #expect(ratings.formattedCompositeScore == "8.6")
        #expect(ratings.compositePercentage == 86)
    }
    
    @Test("Returns nil when no external ratings are available")
    func testAllRatingsNil() {
        let ratings = ExternalRatings()
        #expect(ratings.compositeScore == nil)
        #expect(ratings.formattedCompositeScore == nil)
        #expect(ratings.compositePercentage == nil)
    }
}
