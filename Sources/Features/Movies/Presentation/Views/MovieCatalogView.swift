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
                    // MARK: - Barra Superior Minimalista
                    topBarView
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    
                    // MARK: - Selector de Secciones Minimalista
                    if !viewModel.isSearching {
                        minimalistSectionPicker
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.bottom, 8)
                    }
                    
                    // MARK: - Buscador Minimalista
                    minimalistSearchBar
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, 8)
                    
                    // MARK: - Filtros Contextuales (1 sola línea limpia)
                    if !viewModel.isSearching {
                        if viewModel.selectedSection == .nowPlaying {
                            theatricalFilterRow
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.bottom, 10)
                        } else if viewModel.selectedSection == .classics {
                            classicsFilterRow
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.bottom, 10)
                        }
                    }
                    
                    // MARK: - Contenido Principal (Grid de Posters con tamaño preservado)
                    if viewModel.isLoading && viewModel.displayedMovies.isEmpty {
                        loadingView
                    } else if viewModel.displayedMovies.isEmpty {
                        emptyView
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
                        .font(.system(size: 12, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textTertiary)
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
    
    // MARK: - Subviews: Top Bar View
    
    private var topBarView: some View {
        HStack(alignment: .center) {
            Text(currentSectionTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
            
            // Selector único de ciudad con estética minimalista
            if viewModel.selectedSection == .nowPlaying && !viewModel.isSearching {
                Button {
                    viewModel.isLocationSelectorPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedCity.flagEmoji)
                            .font(.system(size: 12))
                        Text(viewModel.selectedCity.city)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surface)
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
            return "Cartelera"
        case .recommended:
            return "Para Ti"
        case .classics:
            return "Clásicos"
        }
    }
    
    // MARK: - Subviews: Minimalist Section Picker
    
    private var minimalistSectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(MovieCatalogSection.allCases) { section in
                let isSelected = (viewModel.selectedSection == section)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedSection = section
                    }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isSelected ? Theme.Colors.surfaceElevated : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Theme.Colors.border, lineWidth: 0.8)
        )
    }
    
    // MARK: - Subviews: Minimalist Search Bar
    
    private var minimalistSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textTertiary)
            
            TextField("Buscar películas...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
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
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border, lineWidth: 0.8)
        )
    }
    
    // MARK: - Subviews: Theatrical Filter Row (Limpio y en una sola fila)
    
    private var theatricalFilterRow: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    theatricalChip(title: "Todos", filter: .all, count: viewModel.nowPlayingMovies.count)
                    theatricalChip(title: "Estrenos", filter: .premiere, count: viewModel.premiereCount)
                    theatricalChip(title: "2ª Semana", filter: .secondWeek, count: viewModel.secondWeekCount)
                    theatricalChip(title: viewModel.nationalCinemaLabel, filter: .national, count: viewModel.nationalCinemaCount)
                }
                .padding(.vertical, 2)
            }
            
            // Botón de refresco sutil
            Button {
                Task {
                    await viewModel.syncLatestWeekPremieres()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .padding(6)
                    .background(Theme.Colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.Colors.border, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }
    
    private func theatricalChip(title: String, filter: NowPlayingFilter, count: Int) -> some View {
        let isSelected = viewModel.selectedNowPlayingFilter == filter
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.selectNowPlayingFilter(filter)
            }
        } label: {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(isSelected ? .white : Theme.Colors.textTertiary)
                }
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(isSelected ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Theme.Colors.borderFocused : Theme.Colors.border, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews: Classics Filter Row
    
    private var classicsFilterRow: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    decadeChip(title: "Todas", decade: nil)
                    decadeChip(title: "≤ 60s", decade: 1950)
                    decadeChip(title: "70s", decade: 1970)
                    decadeChip(title: "80s", decade: 1980)
                    decadeChip(title: "90s", decade: 1990)
                    decadeChip(title: "2000s", decade: 2000)
                    decadeChip(title: "2010s", decade: 2010)
                }
                .padding(.vertical, 2)
            }
            
            // Toggle de ordenación
            Button {
                Task {
                    await viewModel.toggleClassicsSort()
                }
            } label: {
                Image(systemName: viewModel.classicsSortByRating ? "star.fill" : "calendar")
                    .font(.system(size: 10))
                    .foregroundColor(viewModel.classicsSortByRating ? Theme.Colors.imdb : Theme.Colors.textTertiary)
                    .padding(6)
                    .background(Theme.Colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.Colors.border, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }
    
    private func decadeChip(title: String, decade: Int?) -> some View {
        let isSelected = (viewModel.selectedDecade == decade)
        return Button {
            Task {
                await viewModel.selectDecade(decade)
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(isSelected ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Theme.Colors.borderFocused : Theme.Colors.border, lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews: Movies Grid View
    
    private var moviesGridView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Banner sutil para recomendaciones
                if viewModel.selectedSection == .recommended && !viewModel.isSearching {
                    minimalistRecommendationBanner
                }
                
                // Cuadrícula exacta de 2 columnas conservando el tamaño de los posters
                LazyVGrid(columns: columns, spacing: 16) {
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
    private var minimalistRecommendationBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.recommendationAccent)
            
            Text(viewModel.userRatedCount > 0 ?
                 "Recomendaciones personalizadas basadas en tus calificaciones" :
                 "Puntúa películas para personalizar tus recomendaciones")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border, lineWidth: 0.8)
        )
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Theme.Colors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "film")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Theme.Colors.textTertiary)
            
            Text("No se encontraron películas")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
