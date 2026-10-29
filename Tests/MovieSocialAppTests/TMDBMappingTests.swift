import Testing
import Foundation
@testable import MovieSocialApp

@Suite("TMDB Mapping Tests")
struct TMDBMappingTests {
    @Test("TMDB Response Decoding")
    func tmdbResponseDecoding() throws {
        let json = """
        {
            "page": 1,
            "results": [
                {
                    "id": 693134,
                    "title": "Dune: Part Two",
                    "overview": "Follow the mythic journey of Paul Atreides...",
                    "poster_path": "/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg",
                    "backdrop_path": "/xOMo8BRK7PfcJv9JCnx7s5200bm.jpg",
                    "release_date": "2024-03-01",
                    "vote_average": 8.3,
                    "vote_count": 4800
                }
            ],
            "total_pages": 10,
            "total_results": 200
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(TMDBResponseDTO.self, from: json)
        #expect(response.page == 1)
        #expect(response.results.count == 1)
        
        let movieDTO = response.results[0]
        #expect(movieDTO.id == 693134)
        #expect(movieDTO.title == "Dune: Part Two")
        #expect(movieDTO.releaseDate == "2024-03-01")
    }
}
