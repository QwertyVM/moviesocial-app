import SwiftUI

public struct RootTabView: View {
    @Bindable public var environment: AppEnvironment
    
    @State private var selectedTab: Int = 0
    @State private var selectedMovie: Movie?
    @State private var catalogViewModel: MovieCatalogViewModel?
    @State private var socialViewModel: SocialViewModel?
    @State private var groupsViewModel: GroupsViewModel?
    @State private var profileViewModel: ProfileViewModel?
    
    public init(environment: AppEnvironment) {
        self.environment = environment
    }
    
    public var body: some View {
        Group {
            if let currentUser = environment.authViewModel.currentUser {
                mainTabContent(currentUser: currentUser)
            } else {
                LoginView(viewModel: environment.authViewModel)
            }
        }
        .sheet(item: $selectedMovie) { movie in
            NavigationStack {
                MovieDetailView(
                    viewModel: environment.makeMovieDetailViewModel(movie: movie),
                    currentUser: environment.authViewModel.currentUser
                )
            }
        }
        .onAppear {
            if catalogViewModel == nil {
                catalogViewModel = environment.makeMovieCatalogViewModel()
                socialViewModel = environment.makeSocialViewModel()
                groupsViewModel = environment.makeGroupsViewModel()
                profileViewModel = environment.makeProfileViewModel()
            }
        }
    }
    
    @ViewBuilder
    private func mainTabContent(currentUser: User) -> some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Cine & Catálogo
            if let catalogVM = catalogViewModel {
                MovieCatalogView(viewModel: catalogVM) { movie in
                    self.selectedMovie = movie
                }
                .tabItem {
                    Label("Cine", systemImage: "film")
                }
                .tag(0)
            }
            
            // Tab 1: Amigos & Actividad
            if let socialVM = socialViewModel {
                FriendsFeedView(viewModel: socialVM, currentUser: currentUser) { movieId in
                    selectMovieById(movieId)
                }
                .tabItem {
                    Label("Amigos", systemImage: "person.2")
                }
                .tag(1)
            }
            
            // Tab 2: Cineclubs & Grupos
            if let groupsVM = groupsViewModel {
                GroupsListView(viewModel: groupsVM, currentUser: currentUser) { movieId in
                    selectMovieById(movieId)
                }
                .tabItem {
                    Label("Grupos", systemImage: "person.3.sequence.fill")
                }
                .tag(2)
            }
            
            // Tab 3: Mi Perfil
            if let profileVM = profileViewModel {
                ProfileView(user: currentUser, viewModel: profileVM) {
                    Task {
                        await environment.authViewModel.signOut()
                    }
                }
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle")
                }
                .tag(3)
            }
        }
        .tint(Theme.Colors.textPrimary)
    }
    
    private func selectMovieById(_ movieId: String) {
        Task {
            if let movie = try? await environment.getMovieDetailUseCase.execute(id: movieId) {
                self.selectedMovie = movie
            }
        }
    }
}
