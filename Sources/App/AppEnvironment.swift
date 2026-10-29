import Foundation
import Observation

/// Contenedor de Inyección de Dependencias
@Observable
public final class AppEnvironment: @unchecked Sendable {
    public let movieRepository: MovieRepositoryProtocol
    public let socialRepository: SocialRepositoryProtocol
    public let groupRepository: GroupRepositoryProtocol
    public let authService: AuthServiceProtocol
    
    // Auth
    public let authViewModel: AuthViewModel
    
    // Movie Use Cases
    public let getNowPlayingUseCase: GetNowPlayingMoviesUseCase
    public let getClassicsUseCase: GetClassicsMoviesUseCase
    public let searchMoviesUseCase: SearchMoviesUseCase
    public let getMovieDetailUseCase: GetMovieDetailUseCase
    
    // Social Use Cases
    public let getFriendsActivityUseCase: GetFriendsActivityUseCase
    public let getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase
    public let submitReviewUseCase: SubmitReviewUseCase
    public let getFriendsListUseCase: GetFriendsListUseCase
    public let addFriendUseCase: AddFriendUseCase
    public let addCommentToReviewUseCase: AddCommentToReviewUseCase
    public let toggleLikeReviewUseCase: ToggleLikeReviewUseCase
    
    // Group Use Cases
    public let getGroupsUseCase: GetGroupsUseCase
    public let createGroupUseCase: CreateGroupUseCase
    public let getGroupMessagesUseCase: GetGroupMessagesUseCase
    public let sendGroupMessageUseCase: SendGroupMessageUseCase
    public let joinGroupUseCase: JoinGroupUseCase
    
    public init(
        movieRepository: MovieRepositoryProtocol = MovieRepositoryImpl(),
        socialRepository: SocialRepositoryProtocol = SocialRepositoryImpl(),
        groupRepository: GroupRepositoryProtocol = GroupRepositoryImpl(),
        authService: AuthServiceProtocol = MockAuthService()
    ) {
        self.movieRepository = movieRepository
        self.socialRepository = socialRepository
        self.groupRepository = groupRepository
        self.authService = authService
        
        self.authViewModel = AuthViewModel(authService: authService)
        
        self.getNowPlayingUseCase = GetNowPlayingMoviesUseCase(repository: movieRepository)
        self.getClassicsUseCase = GetClassicsMoviesUseCase(repository: movieRepository)
        self.searchMoviesUseCase = SearchMoviesUseCase(repository: movieRepository)
        self.getMovieDetailUseCase = GetMovieDetailUseCase(repository: movieRepository)
        
        self.getFriendsActivityUseCase = GetFriendsActivityUseCase(repository: socialRepository)
        self.getFriendsReviewsUseCase = GetFriendsReviewsForMovieUseCase(repository: socialRepository)
        self.submitReviewUseCase = SubmitReviewUseCase(repository: socialRepository)
        self.getFriendsListUseCase = GetFriendsListUseCase(repository: socialRepository)
        self.addFriendUseCase = AddFriendUseCase(repository: socialRepository)
        self.addCommentToReviewUseCase = AddCommentToReviewUseCase(repository: socialRepository)
        self.toggleLikeReviewUseCase = ToggleLikeReviewUseCase(repository: socialRepository)
        
        self.getGroupsUseCase = GetGroupsUseCase(repository: groupRepository)
        self.createGroupUseCase = CreateGroupUseCase(repository: groupRepository)
        self.getGroupMessagesUseCase = GetGroupMessagesUseCase(repository: groupRepository)
        self.sendGroupMessageUseCase = SendGroupMessageUseCase(repository: groupRepository)
        self.joinGroupUseCase = JoinGroupUseCase(repository: groupRepository)
    }
    
    public func makeMovieCatalogViewModel() -> MovieCatalogViewModel {
        MovieCatalogViewModel(
            getNowPlayingUseCase: getNowPlayingUseCase,
            getClassicsUseCase: getClassicsUseCase,
            searchMoviesUseCase: searchMoviesUseCase
        )
    }
    
    public func makeMovieDetailViewModel(movie: Movie) -> MovieDetailViewModel {
        MovieDetailViewModel(
            movie: movie,
            getMovieDetailUseCase: getMovieDetailUseCase,
            getFriendsReviewsUseCase: getFriendsReviewsUseCase,
            submitReviewUseCase: submitReviewUseCase,
            addCommentToReviewUseCase: addCommentToReviewUseCase,
            toggleLikeReviewUseCase: toggleLikeReviewUseCase
        )
    }
    
    public func makeSocialViewModel() -> SocialViewModel {
        SocialViewModel(
            getFriendsActivityUseCase: getFriendsActivityUseCase,
            getFriendsListUseCase: getFriendsListUseCase,
            addFriendUseCase: addFriendUseCase,
            addCommentToReviewUseCase: addCommentToReviewUseCase,
            toggleLikeReviewUseCase: toggleLikeReviewUseCase
        )
    }
    
    public func makeGroupsViewModel() -> GroupsViewModel {
        GroupsViewModel(
            getGroupsUseCase: getGroupsUseCase,
            createGroupUseCase: createGroupUseCase,
            getGroupMessagesUseCase: getGroupMessagesUseCase,
            sendGroupMessageUseCase: sendGroupMessageUseCase,
            joinGroupUseCase: joinGroupUseCase
        )
    }
    
    public func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            getFriendsListUseCase: getFriendsListUseCase,
            getFriendsActivityUseCase: getFriendsActivityUseCase
        )
    }
}
