import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Theatrical Release & National Cinema Billboard Tests")
struct TheatricalReleaseAndNationalCinemaTests {
    
    // MARK: - Calculation of Release Week Tests
    
    @Test("Movie calculates premiere week correctly for releases within 0-7 days")
    func testPremiereWeekCalculation() {
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 29))!
        
        let premiereMovie = Movie(
            id: "ekeko_pe_2026",
            title: "Ekeko",
            overview: "Película peruana de terror",
            releaseYear: 2026,
            releaseDate: "2026-10-24", // 5 días de antigüedad
            isInTheatersLocally: true,
            countryOfOrigin: "PE"
        )
        
        let status = premiereMovie.releaseStatus(referenceDate: referenceDate)
        #expect(status == .premiereWeek)
        #expect(status.badgeTitle == "ESTRENO")
    }
    
    @Test("Movie calculates second week correctly for releases between 8-14 days")
    func testSecondWeekCalculation() {
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 29))!
        
        let secondWeekMovie = Movie(
            id: "smile_2_2026",
            title: "Sonríe 2",
            overview: "Terror psicológico",
            releaseYear: 2026,
            releaseDate: "2026-10-17", // 12 días de antigüedad
            isInTheatersLocally: true,
            countryOfOrigin: "US"
        )
        
        let status = secondWeekMovie.releaseStatus(referenceDate: referenceDate)
        #expect(status == .secondWeek)
        #expect(status.badgeTitle == "2ª SEMANA")
    }
    
    @Test("Movie calculates inTheaters for releases older than 14 days actively playing in cinemas")
    func testInTheatersCalculation() {
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 29))!
        
        let longRunMovie = Movie(
            id: "693134",
            title: "Duna: Parte dos",
            overview: "Ciencia ficción",
            releaseYear: 2024,
            releaseDate: "2024-03-01",
            isInTheatersLocally: true
        )
        
        let status = longRunMovie.releaseStatus(referenceDate: referenceDate)
        #expect(status == .inTheaters)
        #expect(status.badgeTitle == "EN CINES")
    }
    
    @Test("Movie calculates coming soon for future release dates")
    func testComingSoonCalculation() {
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 29))!
        
        let futureMovie = Movie(
            id: "future_film",
            title: "Avatar 3",
            overview: "Próximo estreno",
            releaseYear: 2026,
            releaseDate: "2026-12-18"
        )
        
        let status = futureMovie.releaseStatus(referenceDate: referenceDate)
        #expect(status == .comingSoon)
        #expect(status.badgeTitle == "PRÓXIMAMENTE")
    }
    
    // MARK: - Peru & National Cinema Billboard Tests
    
    @Test("Peru billboard includes local Peruvian film Ekeko in theaters with real showtimes")
    func testPeruBillboardIncludesEkeko() async throws {
        let repository = MovieRepositoryImpl()
        
        let limaBillboard = try await repository.getNowPlaying(city: "Lima", countryCode: "PE", page: 1)
        let inTheaters = limaBillboard.filter(\.isInTheatersLocally)
        
        #expect(!inTheaters.isEmpty)
        let ekeko = inTheaters.first(where: { $0.id == "ekeko_pe_2026" })
        #expect(ekeko != nil)
        #expect(ekeko?.title == "Ekeko")
        #expect(ekeko?.countryOfOrigin == "PE")
        #expect(ekeko?.isNationalCinema(for: "PE") == true)
        #expect(ekeko?.isNationalCinema(for: "ES") == false)
        
        // Verifica que cuenta con cines peruanos reales
        let theaters = ekeko?.theatersPlaying ?? []
        #expect(theaters.contains(where: { $0.contains("Cineplanet") || $0.contains("Cinemark") }))
        #expect(!ekeko!.localShowtimes.isEmpty)
    }
    
    @Test("National cinema check identifies origin country across multiple nations")
    func testNationalCinemaOriginCheck() {
        let ekeko = Movie(id: "1", title: "Ekeko", overview: "", releaseYear: 2026, countryOfOrigin: "PE")
        let laSociedad = Movie(id: "2", title: "La Sociedad de la Nieve", overview: "", releaseYear: 2024, countryOfOrigin: "ES")
        let radical = Movie(id: "3", title: "Radical", overview: "", releaseYear: 2024, countryOfOrigin: "MX")
        let puan = Movie(id: "4", title: "Puan", overview: "", releaseYear: 2024, countryOfOrigin: "AR")
        
        #expect(ekeko.isNationalCinema(for: "PE"))
        #expect(!ekeko.isNationalCinema(for: "ES"))
        
        #expect(laSociedad.isNationalCinema(for: "ES"))
        #expect(!laSociedad.isNationalCinema(for: "MX"))
        
        #expect(radical.isNationalCinema(for: "MX"))
        #expect(puan.isNationalCinema(for: "AR"))
    }
    
    // MARK: - MovieCatalogViewModel Theatrical Filter Tests
    
    @Test("MovieCatalogViewModel handles now playing sub-filters (Estrenos, 2ª Semana, Cine Nacional)")
    @MainActor
    func testViewModelTheatricalFilters() async {
        let repo = MovieRepositoryImpl()
        let env = AppEnvironment(movieRepository: repo)
        let vm = env.makeMovieCatalogViewModel()
        
        // Cargar cartelera para Lima, Perú
        let limaLocation = UserLocation(
            city: "Lima",
            country: "Perú",
            countryCode: "PE",
            flagEmoji: "🇵🇪"
        )
        await vm.loadCatalog(userLocation: limaLocation)
        vm.selectedSection = .nowPlaying
        
        // Etiqueta dinámica de cine nacional para Perú
        #expect(vm.nationalCinemaLabel == "🇵🇪 Cine Peruano")
        
        // Sub-filtro: Todos
        vm.selectNowPlayingFilter(.all)
        #expect(vm.displayedMovies.contains(where: { $0.title == "Ekeko" }))
        
        // Sub-filtro: Cine Nacional
        vm.selectNowPlayingFilter(.national)
        let nationalMovies = vm.displayedMovies
        #expect(!nationalMovies.isEmpty)
        #expect(nationalMovies.allSatisfy { $0.countryOfOrigin == "PE" })
        #expect(nationalMovies.contains(where: { $0.title == "Ekeko" }))
        
        // Sub-filtro: Estrenos (Semana 1)
        vm.selectNowPlayingFilter(.premiere)
        let premiereMovies = vm.displayedMovies
        #expect(premiereMovies.allSatisfy { $0.releaseStatus() == .premiereWeek })
        #expect(premiereMovies.contains(where: { $0.title == "Ekeko" }))
        
        // Sub-filtro: 2ª Semana
        vm.selectNowPlayingFilter(.secondWeek)
        let secondWeekMovies = vm.displayedMovies
        #expect(secondWeekMovies.allSatisfy { $0.releaseStatus() == .secondWeek })
        #expect(secondWeekMovies.contains(where: { $0.title == "Sonríe 2" }))
    }
}
