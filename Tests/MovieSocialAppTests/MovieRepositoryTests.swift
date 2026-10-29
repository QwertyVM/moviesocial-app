import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Movie Repository Tests")
struct MovieRepositoryTests {
    let repository: MovieRepositoryProtocol = MovieRepositoryImpl()
    
    @Test("Get Now Playing Returns Recent Movies with Rotten Tomatoes & IMDb")
    func getNowPlayingReturnsRecentMovies() async throws {
        let movies = try await repository.getNowPlaying(page: 1)
        #expect(!movies.isEmpty)
        for movie in movies {
            #expect(movie.releaseYear >= 2024)
            #expect(movie.ratings.rottenTomatoesCritics != nil)
            #expect(movie.ratings.imdbScore != nil)
        }
    }
    
    @Test("Get Classics Returns Historical Masterpieces")
    func getClassicsReturnsHistoricalMasterpieces() async throws {
        let classics = try await repository.getClassics(page: 1)
        #expect(!classics.isEmpty)
        
        let titles = classics.map(\.title)
        #expect(titles.contains(where: { $0.contains("El Padrino") }))
        #expect(titles.contains(where: { $0.contains("Pulp Fiction") }))
    }
    
    @Test("Search Movies Finds Matching Title")
    func searchMoviesFindsMatchingTitle() async throws {
        let results = try await repository.searchMovies(query: "Padrino")
        #expect(!results.isEmpty)
        #expect(results.first?.title == "El Padrino (The Godfather)")
    }
    
    @Test("Get Movie Detail Returns Accurate Rotten Tomatoes & IMDb")
    func getMovieDetailReturnsAccurateRatings() async throws {
        let movie = try await repository.getMovieDetail(id: "238")
        #expect(movie.id == "238")
        #expect(movie.ratings.rottenTomatoesCritics == 97)
        #expect(movie.ratings.imdbScore == 9.2)
    }
}
