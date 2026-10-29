import SwiftUI

public struct MovieCatalogView: View {
    @Bindable public var viewModel: MovieCatalogViewModel
    public let onSelectMovie: (Movie) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    public init(viewModel: MovieCatalogViewModel, onSelectMovie: @escaping (Movie) -> Void) {
        self.viewModel = viewModel
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
                        .padding(.bottom, Theme.Spacing.m)
                    
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
                    await viewModel.loadCatalog()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
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
                            Text(section.rawValue)
                                .font(.system(size: 13, weight: viewModel.selectedSection == section ? .bold : .medium))
                                .foregroundColor(viewModel.selectedSection == section ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
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
            
            TextField("Buscar por título o clásico...", text: $viewModel.searchQuery)
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
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(viewModel.displayedMovies) { movie in
                    MoviePosterCard(movie: movie) {
                        onSelectMovie(movie)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .refreshable {
            await viewModel.loadCatalog()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "film")
                .font(.system(size: 36))
                .foregroundColor(Theme.Colors.textTertiary)
            Text(viewModel.isSearching ? "No se encontraron películas" : "No hay películas disponibles")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
            Spacer()
        }
    }
}

