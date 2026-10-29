import Testing
import Foundation
@testable import MovieSocialApp

@Suite("OMDb Mapping Tests")
struct OMDbMappingTests {
    @Test("OMDb Ratings Parsing")
    func omdbRatingsParsing() throws {
        let json = """
        {
            "Title": "The Godfather",
            "Year": "1972",
            "imdbRating": "9.2",
            "imdbVotes": "2,050,123",
            "Ratings": [
                {
                    "Source": "Internet Movie Database",
                    "Value": "9.2/10"
                },
                {
                    "Source": "Rotten Tomatoes",
                    "Value": "97%"
                },
                {
                    "Source": "Metacritic",
                    "Value": "100/100"
                }
            ],
            "BoxOffice": "$136,381,073"
        }
        """.data(using: .utf8)!
        
        let dto = try JSONDecoder().decode(OMDbMovieDTO.self, from: json)
        let ratings = dto.toExternalRatings()
        
        // Comprobar extracción de Rotten Tomatoes Tomatometer
        #expect(ratings.rottenTomatoesCritics == 97)
        #expect(ratings.formattedTomatometer == "97%")
        
        // Comprobar extracción de IMDb Score
        #expect(ratings.imdbScore == 9.2)
        #expect(ratings.formattedIMDb == "9.2")
        #expect(ratings.imdbVotes == "2,050,123")
    }
}
