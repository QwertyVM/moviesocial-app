import SwiftUI

public struct RootTabView: View {
    @Bindable public var environment: AppEnvironment
    
    @State private var selectedTab: Int = 0
    @State private var selectedMovie: Movie?
    @State private var catalogViewModel: MovieCatalogViewModel?
    @State private var socialViewModel: SocialViewModel?
    @State private var groupsViewModel: GroupsViewModel?
    @State private var directChatViewModel: DirectChatViewModel?
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
        .sheet(item: $selectedMovie, onDismiss: {
            if let user = environment.authViewModel.currentUser {
                Task {
                    await catalogViewModel?.loadRecommendations(userId: user.id)
                    await profileViewModel?.loadProfileData(user: user)
                }
            }
        }) { movie in
            NavigationStack {
                MovieDetailView(
                    viewModel: environment.makeMovieDetailViewModel(movie: movie),
                    currentUser: environment.authViewModel.currentUser,
                    onUpgradeToPremium: {
                        environment.authViewModel.upgradeToPremium()
                    }
                )
            }
        }
        .onAppear {
            if catalogViewModel == nil {
                catalogViewModel = environment.makeMovieCatalogViewModel()
                socialViewModel = environment.makeSocialViewModel()
                groupsViewModel = environment.makeGroupsViewModel()
                directChatViewModel = environment.makeDirectChatViewModel()
                profileViewModel = environment.makeProfileViewModel()
            }
        }
    }
    
    @ViewBuilder
    private func mainTabContent(currentUser: User) -> some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Cine & Catálogo
            if let catalogVM = catalogViewModel {
                MovieCatalogView(viewModel: catalogVM, currentUser: currentUser) { movie in
                    self.selectedMovie = movie
                }
                .tabItem {
                    Label("Cine", systemImage: "film")
                }
                .tag(0)
            }
            
            // Tab 1: Amigos & Actividad
            if let socialVM = socialViewModel {
                FriendsFeedView(
                    viewModel: socialVM,
                    currentUser: currentUser,
                    onOpenChat: { friend in
                        openChatWithFriend(friend)
                    },
                    onSelectMovie: { movieId in
                        selectMovieById(movieId)
                    }
                )
                .tabItem {
                    Label("Amigos", systemImage: "person.2")
                }
                .tag(1)
            }
            
            // Tab 2: Chats (Chats 1 a 1 y Cineclubs)
            if let groupsVM = groupsViewModel, let directVM = directChatViewModel {
                ChatsMainView(
                    directChatViewModel: directVM,
                    groupsViewModel: groupsVM,
                    currentUser: currentUser,
                    onSelectMovie: { movieId in
                        selectMovieById(movieId)
                    }
                )
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(2)
            }
            
            // Tab 3: Mi Perfil
            if let profileVM = profileViewModel {
                ProfileView(
                    user: currentUser,
                    viewModel: profileVM,
                    onUpdateUser: { updatedUser in
                        environment.authViewModel.currentUser = updatedUser
                    },
                    onSignOut: {
                        Task {
                            await environment.authViewModel.signOut()
                        }
                    }
                )
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
    
    private func openChatWithFriend(_ friend: Friend) {
        guard let user = environment.authViewModel.currentUser,
              let directVM = directChatViewModel else { return }
        selectedTab = 2
        Task {
            _ = await directVM.startChatWithFriend(friend, currentUser: user)
        }
    }
}
