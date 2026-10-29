import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Showtimes Service & Historical Classics Tests")
struct ShowtimesAndClassicsTests {
    
    @Test("Showtimes service provides supported cities")
    func testAvailableCities() {
        let service = ShowtimesServiceImpl()
        let cities = service.getAvailableCities()
        
        #expect(!cities.isEmpty)
        let cityNames = cities.map(\.city)
        #expect(cityNames.contains("Madrid"))
        #expect(cityNames.contains("Barcelona"))
        #expect(cityNames.contains("Ciudad de México"))
        #expect(cityNames.contains("Bogotá"))
        #expect(cityNames.contains("Buenos Aires"))
    }
    
    @Test("Showtimes service returns active cinema rooms and hours for Madrid")
    func testMadridShowtimes() async throws {
        let service = ShowtimesServiceImpl()
        let showtimes = try await service.getShowtimes(forMovieId: "693134", city: "Madrid")
        
        #expect(!showtimes.isEmpty)
        let cinemaNames = showtimes.map(\.cinemaName)
        #expect(cinemaNames.contains(where: { $0.contains("Kinépolis") || $0.contains("Ideal") }))
        #expect(showtimes.first?.times.isEmpty == false)
    }
    
    @Test("MovieRepository enriches now playing with local theater information")
    func testNowPlayingEnrichedWithLocalTheaters() async throws {
        let repository = MovieRepositoryImpl()
        let moviesInMadrid = try await repository.getNowPlaying(city: "Madrid", countryCode: "ES", page: 1)
        
        #expect(!moviesInMadrid.isEmpty)
        
        let inTheaters = moviesInMadrid.filter(\.isInTheatersLocally)
        #expect(!inTheaters.isEmpty)
        
        // Películas activas en cines deben ordenarse al inicio
        #expect(moviesInMadrid.first?.isInTheatersLocally == true)
        
        let dune = inTheaters.first(where: { $0.id == "693134" })
        #expect(dune != nil)
        #expect(dune?.theatersPlaying.isEmpty == false)
        #expect(dune?.localShowtimes.isEmpty == false)
    }
    
    @Test("MovieRepository filters classics by decade")
    func testClassicsDecadeFilter() async throws {
        let repository = MovieRepositoryImpl()
        
        // 70s
        let seventies = try await repository.getClassics(decade: 1970, sortByRating: true, page: 1)
        #expect(!seventies.isEmpty)
        #expect(seventies.allSatisfy { $0.releaseYear >= 1970 && $0.releaseYear <= 1979 })
        #expect(seventies.contains(where: { $0.title.contains("El Padrino") }))
        
        // Vintage <= 1960s
        let vintage = try await repository.getClassics(decade: 1950, sortByRating: true, page: 1)
        #expect(!vintage.isEmpty)
        #expect(vintage.allSatisfy { $0.releaseYear <= 1969 })
        #expect(vintage.contains(where: { $0.title.contains("12 Hombres en Pugna") || $0.title.contains("Casablanca") }))
    }
    
    @Test("MovieRepository sorts classics descending by composite score")
    func testClassicsSortedByCompositeScore() async throws {
        let repository = MovieRepositoryImpl()
        let classics = try await repository.getClassics(decade: nil, sortByRating: true, page: 1)
        
        #expect(!classics.isEmpty)
        
        for i in 0..<(classics.count - 1) {
            let score1 = classics[i].ratings.compositeScore ?? 0.0
            let score2 = classics[i + 1].ratings.compositeScore ?? 0.0
            #expect(score1 >= score2)
        }
    }
    
    @Test("MovieCatalogViewModel updates showtimes when selecting a different city")
    @MainActor
    func testCatalogViewModelCitySwitch() async {
        let repo = MovieRepositoryImpl()
        let env = AppEnvironment(movieRepository: repo)
        let vm = env.makeMovieCatalogViewModel()
        
        await vm.loadCatalog()
        #expect(vm.selectedCity.city == "Madrid")
        
        let cdmx = UserLocation(city: "Ciudad de México", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", isLocal: true)
        await vm.selectCity(cdmx)
        
        #expect(vm.selectedCity.city == "Ciudad de México")
        let inTheatersCDMX = vm.nowPlayingMovies.filter(\.isInTheatersLocally)
        #expect(!inTheatersCDMX.isEmpty)
        let theaters = inTheatersCDMX.flatMap(\.theatersPlaying)
        #expect(theaters.contains(where: { $0.contains("Cinépolis") || $0.contains("Cinemex") || $0.contains("Cineteca") }))
    }
    
    @Test("MovieCatalogViewModel updates classics when selecting decade filter")
    @MainActor
    func testCatalogViewModelDecadeFilter() async {
        let repo = MovieRepositoryImpl()
        let env = AppEnvironment(movieRepository: repo)
        let vm = env.makeMovieCatalogViewModel()
        
        await vm.loadCatalog()
        #expect(vm.selectedDecade == nil)
        
        await vm.selectDecade(1990)
        #expect(vm.selectedDecade == 1990)
        #expect(!vm.classicMovies.isEmpty)
        #expect(vm.classicMovies.allSatisfy { $0.releaseYear >= 1990 && $0.releaseYear <= 1999 })
    }
}
