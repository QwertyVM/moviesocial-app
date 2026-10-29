import SwiftUI

public struct MovieCatalogView: View {
    @Bindable public var viewModel: MovieCatalogViewModel
    public let currentUser: User?
    public let onSelectMovie: (Movie) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    public init(
        viewModel: MovieCatalogViewModel,
        currentUser: User? = nil,
        onSelectMovie: @escaping (Movie) -> Void
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onSelectMovie = onSelectMovie
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con selector minimalista
                    headerView
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, Theme.Spacing.s)
                        .padding(.bottom, Theme.Spacing.s)
                    
                    // Search Bar minimalista
                    searchBarView
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, Theme.Spacing.s)
                    
                    // Controles contextuales por pestaña (Cartelera por Ciudad / Clásicos por Década)
                    if !viewModel.isSearching {
                        if viewModel.selectedSection == .nowPlaying {
                            cityFilterHeader
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.bottom, Theme.Spacing.s)
                        } else if viewModel.selectedSection == .classics {
                            classicsFilterHeader
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.bottom, Theme.Spacing.s)
                        }
                    }
                    
                    // Contenido
                    if viewModel.isLoading && viewModel.displayedMovies.isEmpty {
                        Spacer()
                        ProgressView()
                            .tint(Theme.Colors.textPrimary)
                        Spacer()
                    } else if viewModel.displayedMovies.isEmpty {
                        emptyStateView
                    } else {
                        moviesGridView
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CATÁLOGO")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .task {
                if viewModel.nowPlayingMovies.isEmpty {
                    await viewModel.loadCatalog(
                        userId: currentUser?.id,
                        userLocation: currentUser?.location
                    )
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var cityFilterHeader: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(viewModel.availableCities, id: \.city) { location in
                    Button {
                        Task {
                            await viewModel.selectCity(location)
                        }
                    } label: {
                        HStack {
                            Text("\(location.flagEmoji) \(location.city)")
                            if viewModel.selectedCity.city == location.city {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.recommendationAccent)
                    
                    Text("\(viewModel.selectedCity.flagEmoji) \(viewModel.selectedCity.city)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            
            Text("Cartelera en cines")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
            
            Spacer()
            
            let inTheatersCount = viewModel.nowPlayingMovies.filter(\.isInTheatersLocally).count
            if inTheatersCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "ticket")
                        .font(.system(size: 10))
                    Text("\(inTheatersCount) activas")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(Color.green)
            }
        }
    }
    
    private var classicsFilterHeader: some View {
        VStack(spacing: 8) {
            // Décadas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    decadeButton(title: "Todas", decade: nil)
                    decadeButton(title: "≤ 60s", decade: 1950)
                    decadeButton(title: "70s", decade: 1970)
                    decadeButton(title: "80s", decade: 1980)
                    decadeButton(title: "90s", decade: 1990)
                    decadeButton(title: "2000s", decade: 2000)
                    decadeButton(title: "2010s", decade: 2010)
                }
            }
            
            // Sub-indicador de ordenación por Cruce de Ratings (IMDb + RT)
            HStack {
                Button {
                    Task {
                        await viewModel.toggleClassicsSort()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text(viewModel.classicsSortByRating ? "Orden: Score IMDb + RT (Blended)" : "Orden: Cronológico")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.recommendationAccent)
                }
                
                Spacer()
                
                Text("\(viewModel.classicMovies.count) obras maestras")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
    }
    
    private func decadeButton(title: String, decade: Int?) -> some View {
        let isSelected = (viewModel.selectedDecade == decade)
        return Button {
            Task {
                await viewModel.selectDecade(decade)
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Theme.Colors.border : Color.clear, lineWidth: 1)
                )
        }
    }
    
    private var headerView: some View {
        HStack {
            if !viewModel.isSearching {
                HStack(spacing: 4) {
                    ForEach(MovieCatalogSection.allCases) { section in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedSection = section
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if section == .recommended {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                Text(section.rawValue)
                                    .font(.system(size: 13, weight: viewModel.selectedSection == section ? .bold : .medium))
                            }
                            .foregroundColor(
                                viewModel.selectedSection == section ?
                                    (section == .recommended ? Theme.Colors.recommendationAccent : Theme.Colors.textPrimary) :
                                    Theme.Colors.textTertiary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                viewModel.selectedSection == section ?
                                Theme.Colors.surfaceElevated : Color.clear
                            )
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(3)
                .background(Theme.Colors.surface)
                .clipShape(Capsule())
            } else {
                Text("Resultados para \"\(viewModel.searchQuery)\"")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
    
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textTertiary)
            
            TextField("Buscar por título, género o clásico...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textPrimary)
                .autocorrectionDisabled()
                .onSubmit {
                    Task {
                        await viewModel.performSearch()
                    }
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var moviesGridView: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Banner contextual de recomendaciones
                if viewModel.selectedSection == .recommended && !viewModel.isSearching {
                    recommendationHeaderBadge
                }
                
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(viewModel.displayedMovies) { movie in
                        MoviePosterCard(movie: movie) {
                            onSelectMovie(movie)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .refreshable {
            await viewModel.loadCatalog(
                userId: currentUser?.id,
                userLocation: currentUser?.location
            )
        }
    }
    
    private var recommendationHeaderBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.Colors.recommendationAccent)
            
            Text("Basado en tus \(viewModel.userRatedCount) películas calificadas")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
            
            if !viewModel.topGenrePreferences.isEmpty {
                Text("•")
                    .foregroundColor(Theme.Colors.textTertiary)
                Text(viewModel.topGenrePreferences.joined(separator: ", "))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if viewModel.selectedSection == .recommended && !viewModel.isSearching {
                // Cold start para recomendaciones
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.recommendationAccent.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.recommendationAccent)
                    }
                    
                    Text("Recomendaciones para ti")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Aún no has calificado ninguna película con estrellas. Califica tus películas favoritas para que el recomendador aprenda tus preferencias cinematográficas.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(3)
                    
                    Button {
                        withAnimation {
                            viewModel.selectedSection = .nowPlaying
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Explorar Estrenos y Calificar")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.large)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
                .padding(.horizontal, Theme.Spacing.m)
            } else {
                Image(systemName: "film")
                    .font(.system(size: 36))
                    .foregroundColor(Theme.Colors.textTertiary)
                Text(viewModel.isSearching ? "No se encontraron películas" : "No hay películas disponibles")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}
