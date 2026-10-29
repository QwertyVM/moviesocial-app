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
    
    // Cartelera Local por Ciudad
    public var selectedCity: UserLocation = UserLocation(
        city: "Madrid",
        country: "España",
        countryCode: "ES",
        flagEmoji: "🇪🇸",
        isLocal: true
    )
    public var availableCities: [UserLocation] = [
        UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
        UserLocation(city: "Barcelona", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
        UserLocation(city: "Ciudad de México", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", isLocal: true),
        UserLocation(city: "Bogotá", country: "Colombia", countryCode: "CO", flagEmoji: "🇨🇴", isLocal: true),
        UserLocation(city: "Buenos Aires", country: "Argentina", countryCode: "AR", flagEmoji: "🇦🇷", isLocal: true),
        UserLocation(city: "Santiago", country: "Chile", countryCode: "CL", flagEmoji: "🇨🇱", isLocal: true),
        UserLocation(city: "Lima", country: "Perú", countryCode: "PE", flagEmoji: "🇵🇪", isLocal: true)
    ]
    
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
            return nowPlayingMovies
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
}
