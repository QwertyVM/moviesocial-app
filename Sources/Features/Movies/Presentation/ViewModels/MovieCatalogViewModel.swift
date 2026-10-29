import Foundation
import Observation

@Observable
public final class MovieCatalogViewModel: @unchecked Sendable {
    public var selectedSection: MovieCatalogSection = .nowPlaying
    public var searchQuery: String = ""
    public var nowPlayingMovies: [Movie] = []
    public var classicMovies: [Movie] = []
    public var searchResults: [Movie] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    private let getNowPlayingUseCase: GetNowPlayingMoviesUseCase
    private let getClassicsUseCase: GetClassicsMoviesUseCase
    private let searchMoviesUseCase: SearchMoviesUseCase
    
    public init(
        getNowPlayingUseCase: GetNowPlayingMoviesUseCase,
        getClassicsUseCase: GetClassicsMoviesUseCase,
        searchMoviesUseCase: SearchMoviesUseCase
    ) {
        self.getNowPlayingUseCase = getNowPlayingUseCase
        self.getClassicsUseCase = getClassicsUseCase
        self.searchMoviesUseCase = searchMoviesUseCase
    }
    
    public var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var displayedMovies: [Movie] {
        if isSearching {
            return searchResults
        }
        switch selectedSection {
        case .nowPlaying:
            return nowPlayingMovies
        case .classics:
            return classicMovies
        }
    }
    
    @MainActor
    public func loadCatalog() async {
        isLoading = true
        errorMessage = nil
        do {
            async let nowPlaying = getNowPlayingUseCase.execute(page: 1)
            async let classics = getClassicsUseCase.execute(page: 1)
            self.nowPlayingMovies = try await nowPlaying
            self.classicMovies = try await classics
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
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

