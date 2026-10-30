import SwiftUI

public struct MovieCatalogView: View {
    @Bindable public var viewModel: MovieCatalogViewModel
    public let currentUser: User?
    public let onSelectMovie: (Movie) -> Void
    
    // Cuadrícula de 2 columnas manteniendo el tamaño exacto y proporcionado de los posters (2:3)
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
                    // MARK: - Top Navigation Bar & Brand
                    topBrandingBar
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    
                    // MARK: - Segmented Navigation Pill Selector
                    if !viewModel.isSearching {
                        sectionSegmentedControl
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.bottom, 10)
                    }
                    
                    // MARK: - Search Bar Minimalista y Cinematográfica
                    searchBarView
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, 10)
                    
                    // MARK: - Toolbars Contextuales (En Cartelera / Clásicos)
                    if !viewModel.isSearching {
                        if viewModel.selectedSection == .nowPlaying {
                            theatricalControlBar
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.bottom, 10)
                        } else if viewModel.selectedSection == .classics {
                            classicsControlBar
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.bottom, 10)
                        }
                    }
                    
                    // MARK: - Contenido Principal (Grid de Posters)
                    if viewModel.isLoading && viewModel.displayedMovies.isEmpty {
                        loadingStateView
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
                    Text("MOVIESOCIAL")
                        .font(.system(size: 13, weight: .black))
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
    
    // MARK: - Subviews: Top Branding Bar
    
    private var topBrandingBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentSectionTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(currentSectionSubtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            
            Spacer()
            
            // Acceso rápido a ubicación si estamos en cartelera
            if viewModel.selectedSection == .nowPlaying && !viewModel.isSearching {
                Button {
                    viewModel.isLocationSelectorPresented = true
                } label: {
                    HStack(spacing: 5) {
                        Text(viewModel.selectedCity.flagEmoji)
                            .font(.system(size: 13))
                        Text(viewModel.selectedCity.city)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Theme.Colors.border, lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var currentSectionTitle: String {
        if viewModel.isSearching {
            return "Búsqueda"
        }
        switch viewModel.selectedSection {
        case .nowPlaying:
            return "En Cartelera"
        case .recommended:
            return "Para Ti"
        case .classics:
            return "Joyas del Cine"
        }
    }
    
    private var currentSectionSubtitle: String {
        if viewModel.isSearching {
            return "Resultados para \"\(viewModel.searchQuery)\""
        }
        switch viewModel.selectedSection {
        case .nowPlaying:
            return "Estrenos semanales y salas de cine"
        case .recommended:
            return "Curadas según tus gustos cinéfilos"
        case .classics:
            return "Obras maestras de la historia del cine"
        }
    }
    
    // MARK: - Subviews: Segmented Control
    
    private var sectionSegmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(MovieCatalogSection.allCases) { section in
                let isSelected = (viewModel.selectedSection == section)
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        viewModel.selectedSection = section
                    }
                } label: {
                    HStack(spacing: 5) {
                        if section == .recommended {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .bold))
                        } else if section == .nowPlaying {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 10))
                        } else {
                            Image(systemName: "film.stack")
                                .font(.system(size: 10))
                        }
                        
                        Text(section.rawValue)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundColor(
                        isSelected ?
                            (section == .recommended ? Theme.Colors.recommendationAccent : Theme.Colors.textPrimary) :
                            Theme.Colors.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isSelected ? Theme.Colors.surfaceElevated : Color.clear
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            isSelected ?
                                (section == .recommended ? Theme.Colors.recommendationAccent.opacity(0.4) : Theme.Colors.border) :
                                Color.clear,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
        )
    }
    
    // MARK: - Subviews: Search Bar
    
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.textTertiary)
            
            TextField("Buscar películas, directores o clásicos...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13.5))
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
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.Colors.border.opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - Subviews: Theatrical Control Bar (Cartelera en cines)
    
    private var theatricalControlBar: some View {
        VStack(spacing: 8) {
            // Fila superior: Ubicación activa + Botón GPS + Contador En Cartelera + Refresh
            HStack(spacing: 8) {
                // Selector de Ciudad / Región
                Button {
                    viewModel.isLocationSelectorPresented = true
                } label: {
                    HStack(spacing: 5) {
                        if viewModel.selectedCity.isDeviceLocation {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        } else {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.recommendationAccent)
                        }
                        
                        Text(viewModel.selectedCity.shortLabel)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        if let area = viewModel.selectedCity.area, !area.isEmpty, area.lowercased() != viewModel.selectedCity.city.lowercased() {
                            Text("• \(area)")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundColor(Theme.Colors.textTertiary)
                                .lineLimit(1)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            viewModel.selectedCity.isDeviceLocation ? Color.green.opacity(0.4) : Theme.Colors.border,
                            lineWidth: 0.9
                        )
                    )
                }
                .buttonStyle(.plain)
                
                // Botón GPS de 1-tap
                Button {
                    Task {
                        await viewModel.useDeviceLocation()
                    }
                } label: {
                    HStack(spacing: 3.5) {
                        if viewModel.isDetectingLocation {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 11, height: 11)
                        } else {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 9.5, weight: .bold))
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
                        Capsule().stroke(viewModel.selectedCity.isDeviceLocation ? Color.green.opacity(0.4) : Theme.Colors.border, lineWidth: 0.9)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDetectingLocation)
                
                Spacer()
                
                // Contador en vivo de películas en cartelera y botón de refresco
                let inTheatersCount = viewModel.nowPlayingMovies.filter(\.isInTheatersLocally).count
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(inTheatersCount > 0 ? Color.green : Theme.Colors.textTertiary)
                            .frame(width: 5.5, height: 5.5)
                        Text("\(inTheatersCount) en cartelera")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(inTheatersCount > 0 ? Color.green : Theme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surface.opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(inTheatersCount > 0 ? Color.green.opacity(0.25) : Theme.Colors.border, lineWidth: 0.8)
                    )

                    Button {
                        Task {
                            await viewModel.syncLatestWeekPremieres()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(6)
                            .background(Theme.Colors.surfaceElevated)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Theme.Colors.border, lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Fila inferior: Sub-filtros dinámicos de cartelera (Todos, Estrenos de la semana, 2ª Semana y Cine Local)
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
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectNowPlayingFilter(filter)
            }
        } label: {
            HStack(spacing: 4.5) {
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
                Capsule().stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews: Classics Control Bar
    
    private var classicsControlBar: some View {
        VStack(spacing: 8) {
            // Filtro por décadas
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
                .padding(.vertical, 2)
            }
            
            // Fila de ordenación ponderada y total de clásicos
            HStack {
                Button {
                    Task {
                        await viewModel.toggleClassicsSort()
                    }
                } label: {
                    HStack(spacing: 4.5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.Colors.imdb)
                        Text(viewModel.classicsSortByRating ? "Orden: Score IMDb + RT (Blended)" : "Orden: Cronológico")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Theme.Colors.recommendationAccent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .background(Theme.Colors.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Theme.Colors.recommendationAccent.opacity(0.3), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(viewModel.classicMovies.count) obras maestras")
                    .font(.system(size: 10.5, weight: .medium))
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
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews: Movies Grid View
    
    private var moviesGridView: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Banner contextual si estamos en Recomendaciones
                if viewModel.selectedSection == .recommended && !viewModel.isSearching {
                    recommendationHeaderBadge
                }
                
                // Cuadrícula de 2 columnas conservando el tamaño exacto de poster
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
    
    // MARK: - Subviews: Recommendation Header Badge
    
    @ViewBuilder
    private var recommendationHeaderBadge: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.recommendationAccent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.Colors.recommendationAccent)
                    .font(.system(size: 13, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.userRatedCount > 0 {
                    Text("RECOMENDACIONES PARA TI")
                        .font(.system(size: 9.5, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.recommendationAccent)
                    
                    if !viewModel.topGenrePreferences.isEmpty {
                        Text("Basadas en tus gustos por \(viewModel.topGenrePreferences.joined(separator: ", "))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                } else {
                    Text("DESCUBRE NUEVAS PELÍCULAS")
                        .font(.system(size: 9.5, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("Puntúa 1 o más películas para desbloquear tu algoritmo personalizado.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.s + 2)
        .background(Theme.Colors.surfaceElevated.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.recommendationAccent.opacity(0.25), lineWidth: 0.9)
        )
    }
    
    // MARK: - Subviews: Loading & Empty States
    
    private var loadingStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .tint(Theme.Colors.textPrimary)
                .scaleEffect(1.2)
            Text("Cargando cartelera...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 72, height: 72)
                Image(systemName: "film")
                    .font(.system(size: 30))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            
            Text("No se encontraron películas")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Intenta con otro término o selecciona otra ciudad en cartelera.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if viewModel.selectedNowPlayingFilter != .all {
                Button {
                    viewModel.selectNowPlayingFilter(.all)
                } label: {
                    Text("Ver todas en cartelera")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Theme.Colors.textPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
