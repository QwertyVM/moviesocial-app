import Foundation
import Observation

@Observable
public final class MovieCatalogViewModel: @unchecked Sendable {
    public var selectedSection: MovieCatalogSection = .recommended
    public var searchQuery: String = ""
    public var recommendedMovies: [Movie] = []
    public var nowPlayingMovies: [Movie] = []
    public var classicMovies: [Movie] = []
    public var searchResults: [Movie] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // Metadatos de personalización
    public var userRatedCount: Int = 0
    public var topGenrePreferences: [String] = []
    
    // Cartelera y Ubicación Inteligente (Dispositivo / País / Área)
    public var selectedCity: UserLocation = UserLocation(
        city: "Madrid",
        country: "España",
        countryCode: "ES",
        flagEmoji: "🇪🇸",
        isLocal: true,
        area: "Comunidad de Madrid"
    )
    public var availableCities: [UserLocation] = []
    public var countryGroups: [CountryAreaGroup] = []
    public var isDetectingLocation: Bool = false
    public var isLocationSelectorPresented: Bool = false
    
    // Filtros de Cartelera: Estrenos (Semana 1), 2ª Semana y Cine Nacional
    public var selectedNowPlayingFilter: NowPlayingFilter = .all
    
    // Clásicos Históricos por Cruce de Ratings (IMDb + RT) y Filtro de Épocas
    public var selectedDecade: Int? = nil // nil = "Todas"
    public var classicsSortByRating: Bool = true
    
    private let getNowPlayingUseCase: GetNowPlayingMoviesUseCase
    private let getClassicsUseCase: GetClassicsMoviesUseCase
    private let searchMoviesUseCase: SearchMoviesUseCase
    private let getRecommendedMoviesUseCase: GetRecommendedMoviesUseCase
    
    public init(
        getNowPlayingUseCase: GetNowPlayingMoviesUseCase,
        getClassicsUseCase: GetClassicsMoviesUseCase,
        searchMoviesUseCase: SearchMoviesUseCase,
        getRecommendedMoviesUseCase: GetRecommendedMoviesUseCase,
        initialCity: UserLocation? = nil
    ) {
        self.getNowPlayingUseCase = getNowPlayingUseCase
        self.getClassicsUseCase = getClassicsUseCase
        self.searchMoviesUseCase = searchMoviesUseCase
        self.getRecommendedMoviesUseCase = getRecommendedMoviesUseCase
        
        let showtimes = ShowtimesServiceImpl()
        self.availableCities = showtimes.getAvailableCities()
        self.countryGroups = showtimes.getAvailableCountryGroups()
        
        if let initialCity {
            self.selectedCity = initialCity
        }
    }
    
    public var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var displayedMovies: [Movie] {
        if isSearching {
            return searchResults
        }
        switch selectedSection {
        case .recommended:
            return recommendedMovies
        case .nowPlaying:
            switch selectedNowPlayingFilter {
            case .all:
                return nowPlayingMovies
            case .premiere:
                return nowPlayingMovies.filter { $0.releaseStatus() == .premiereWeek }
            case .secondWeek:
                return nowPlayingMovies.filter { $0.releaseStatus() == .secondWeek }
            case .national:
                return nowPlayingMovies.filter { $0.isNationalCinema(for: selectedCity.countryCode) }
            }
        case .classics:
            return classicMovies
        }
    }
    
    @MainActor
    public func loadCatalog(userId: String? = nil, userLocation: UserLocation? = nil) async {
        if let userLocation {
            self.selectedCity = userLocation
        }
        isLoading = true
        errorMessage = nil
        do {
            async let nowPlaying = getNowPlayingUseCase.execute(
                city: selectedCity.city,
                countryCode: selectedCity.countryCode,
                page: 1
            )
            async let classics = getClassicsUseCase.execute(
                decade: selectedDecade,
                sortByRating: classicsSortByRating,
                page: 1
            )
            self.nowPlayingMovies = try await nowPlaying
            self.classicMovies = try await classics
            
            if let userId {
                await loadRecommendations(userId: userId)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func selectCity(_ location: UserLocation) async {
        self.selectedCity = location
        do {
            self.nowPlayingMovies = try await getNowPlayingUseCase.execute(
                city: location.city,
                countryCode: location.countryCode,
                page: 1
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func selectLocation(_ location: UserLocation) async {
        await selectCity(location)
    }
    
    /// Detección inteligente de la ubicación del dispositivo mediante GPS o configuración regional
    @MainActor
    public func useDeviceLocation() async {
        isDetectingLocation = true
        let detected = await DeviceLocationService.shared.detectDeviceLocation()
        await selectCity(detected)
        isDetectingLocation = false
    }
    
    @MainActor
    public func selectDecade(_ decade: Int?) async {
        self.selectedDecade = decade
        do {
            self.classicMovies = try await getClassicsUseCase.execute(
                decade: decade,
                sortByRating: classicsSortByRating,
                page: 1
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func toggleClassicsSort() async {
        self.classicsSortByRating.toggle()
        do {
            self.classicMovies = try await getClassicsUseCase.execute(
                decade: selectedDecade,
                sortByRating: classicsSortByRating,
                page: 1
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func loadRecommendations(userId: String) async {
        do {
            let result = try await getRecommendedMoviesUseCase.execute(userId: userId)
            self.recommendedMovies = result.movies
            self.userRatedCount = result.userRatedCount
            self.topGenrePreferences = result.topGenres
        } catch {
            // Silently fall back to empty recommendations
            self.recommendedMovies = []
        }
    }
    
    @MainActor
    public func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isLoading = true
        do {
            self.searchResults = try await searchMoviesUseCase.execute(query: query)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Filtros de Cartelera y Cine Nacional
    
    @MainActor
    public func selectNowPlayingFilter(_ filter: NowPlayingFilter) {
        self.selectedNowPlayingFilter = filter
    }
    
    public var premiereCount: Int {
        nowPlayingMovies.filter { $0.releaseStatus() == .premiereWeek }.count
    }
    
    public var secondWeekCount: Int {
        nowPlayingMovies.filter { $0.releaseStatus() == .secondWeek }.count
    }
    
    public var nationalCinemaCount: Int {
        nowPlayingMovies.filter { $0.isNationalCinema(for: selectedCity.countryCode) }.count
    }
    
    public var nationalCinemaLabel: String {
        switch selectedCity.countryCode.uppercased() {
        case "PE": return "🇵🇪 Cine Peruano"
        case "ES": return "🇪🇸 Cine Español"
        case "MX": return "🇲🇽 Cine Mexicano"
        case "AR": return "🇦🇷 Cine Argentino"
        case "FR": return "🇫🇷 Cine Francés"
        case "JP": return "🇯🇵 Cine Japonés"
        case "CO": return "🇨🇴 Cine Colombiano"
        case "CL": return "🇨🇱 Cine Chileno"
        case "US": return "🇺🇸 Cine USA"
        default: return "🎬 Cine Nacional"
        }
    }
}

/// Filtros para la cartelera en cines (Estrenos, 2ª semana, Cine nacional)
public enum NowPlayingFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "Todos"
    case premiere = "Estrenos"
    case secondWeek = "2ª Semana"
    case national = "Cine Nacional"
    
    public var id: String { rawValue }
}
