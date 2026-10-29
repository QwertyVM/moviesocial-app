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
                        .font(.system(size: 14, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .sheet(isPresented: $viewModel.isLocationSelectorPresented) {
                LocationSelectorSheetView(
                    viewModel: viewModel,
                    onLocationSelected: { location in
                        Task {
                            await viewModel.selectCity(location)
                        }
                    }
                )
            }
            .task {
                await viewModel.loadCatalog(
                    userId: currentUser?.id,
                    userLocation: currentUser?.location
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var cityFilterHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Pill de ubicación minimalista e inteligente
                Button {
                    viewModel.isLocationSelectorPresented = true
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.selectedCity.isDeviceLocation {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.recommendationAccent)
                        }
                        
                        Text(viewModel.selectedCity.shortLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        if let area = viewModel.selectedCity.area, !area.isEmpty, area.lowercased() != viewModel.selectedCity.city.lowercased() {
                            Text("• \(area)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.Colors.textTertiary)
                                .lineLimit(1)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            viewModel.selectedCity.isDeviceLocation ? Color.green.opacity(0.5) : Theme.Colors.border,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
                
                // Botón inteligente de GPS rápido (1-tap)
                Button {
                    Task {
                        await viewModel.useDeviceLocation()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.isDetectingLocation {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text("GPS")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(viewModel.selectedCity.isDeviceLocation ? .green : Theme.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.surfaceElevated.opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(viewModel.selectedCity.isDeviceLocation ? Color.green.opacity(0.5) : Theme.Colors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDetectingLocation)
                
                Spacer()
                
                // Contador inteligente de cartelera en cines y botón de actualización a hoy
                let inTheatersCount = viewModel.nowPlayingMovies.filter(\.isInTheatersLocally).count
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(inTheatersCount > 0 ? Color.green : Theme.Colors.textTertiary)
                            .frame(width: 6, height: 6)
                        Text("\(inTheatersCount) en cartelera")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(inTheatersCount > 0 ? Color.green : Theme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surface.opacity(0.6))
                    .clipShape(Capsule())

                    Button {
                        Task {
                            await viewModel.syncLatestWeekPremieres()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(6)
                            .background(Theme.Colors.surfaceElevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Sub-filtros dinámicos de cartelera: Todos, Estrenos de la semana, 2ª Semana y Cine Local/Nacional
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    theatricalFilterButton(
                        title: "Todos",
                        filter: .all,
                        count: viewModel.nowPlayingMovies.count
                    )
                    theatricalFilterButton(
                        title: "🌟 Estrenos",
                        filter: .premiere,
                        count: viewModel.premiereCount
                    )
                    theatricalFilterButton(
                        title: "🎟️ 2ª Semana",
                        filter: .secondWeek,
                        count: viewModel.secondWeekCount
                    )
                    theatricalFilterButton(
                        title: viewModel.nationalCinemaLabel,
                        filter: .national,
                        count: viewModel.nationalCinemaCount
                    )
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private func theatricalFilterButton(title: String, filter: NowPlayingFilter, count: Int) -> some View {
        let isSelected = viewModel.selectedNowPlayingFilter == filter
        return Button {
            viewModel.selectNowPlayingFilter(filter)
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.25) : Theme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .black : Theme.Colors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Theme.Colors.textPrimary : Theme.Colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                        MoviePosterCard(
                            movie: movie,
                            selectedCountryCode: viewModel.selectedCity.countryCode
                        ) {
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
    
    @ViewBuilder
    private var recommendationHeaderBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundColor(Theme.Colors.recommendationAccent)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.userRatedCount > 0 {
                    Text("RECOMENDACIONES PARA TI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.recommendationAccent)
                    
                    if !viewModel.topGenrePreferences.isEmpty {
                        Text("Basadas en tus gustos por \(viewModel.topGenrePreferences.joined(separator: ", "))")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                } else {
                    Text("DESCUBRE NUEVAS PELÍCULAS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("Puntúa 1 o más películas para desbloquear tu algoritmo personalizado.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.s)
        .background(Theme.Colors.surfaceElevated.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "film")
                .font(.system(size: 44))
                .foregroundColor(Theme.Colors.textTertiary)
            
            Text("No se encontraron películas")
                .font(.headline)
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Intenta con otro término o cambia tu filtro.")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
