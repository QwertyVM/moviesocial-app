import Foundation
import Observation

/// Contenedor de Inyección de Dependencias
@Observable
public final class AppEnvironment: @unchecked Sendable {
    public let movieRepository: MovieRepositoryProtocol
    public let socialRepository: SocialRepositoryProtocol
    public let groupRepository: GroupRepositoryProtocol
    public let directChatRepository: DirectChatRepositoryProtocol
    public let authService: AuthServiceProtocol
    
    // Auth
    public let authViewModel: AuthViewModel
    
    // Movie Use Cases
    public let getNowPlayingUseCase: GetNowPlayingMoviesUseCase
    public let getClassicsUseCase: GetClassicsMoviesUseCase
    public let searchMoviesUseCase: SearchMoviesUseCase
    public let getMovieDetailUseCase: GetMovieDetailUseCase
    public let getRecommendedMoviesUseCase: GetRecommendedMoviesUseCase
    
    // Social Use Cases
    public let getFriendsActivityUseCase: GetFriendsActivityUseCase
    public let getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase
    public let getCommunityReviewsUseCase: GetCommunityReviewsUseCase
    public let submitReviewUseCase: SubmitReviewUseCase
    public let editReviewUseCase: EditReviewUseCase
    public let getFriendsListUseCase: GetFriendsListUseCase
    public let addFriendUseCase: AddFriendUseCase
    public let removeFriendUseCase: RemoveFriendUseCase
    public let addCommentToReviewUseCase: AddCommentToReviewUseCase
    public let toggleLikeReviewUseCase: ToggleLikeReviewUseCase
    public let toggleHelpfulReviewUseCase: ToggleHelpfulReviewUseCase
    
    // Group Use Cases
    public let getGroupsUseCase: GetGroupsUseCase
    public let createGroupUseCase: CreateGroupUseCase
    public let getGroupMessagesUseCase: GetGroupMessagesUseCase
    public let sendGroupMessageUseCase: SendGroupMessageUseCase
    public let joinGroupUseCase: JoinGroupUseCase
    public let joinGroupByInviteCodeUseCase: JoinGroupByInviteCodeUseCase
    public let addMembersToGroupUseCase: AddMembersToGroupUseCase
    
    // Direct Chat (One-to-One) Use Cases
    public let getDirectConversationsUseCase: GetDirectConversationsUseCase
    public let getOrCreateDirectConversationUseCase: GetOrCreateDirectConversationUseCase
    public let getDirectMessagesUseCase: GetDirectMessagesUseCase
    public let sendDirectMessageUseCase: SendDirectMessageUseCase
    public let markDirectMessagesAsReadUseCase: MarkDirectMessagesAsReadUseCase
    
    public init(
        movieRepository: MovieRepositoryProtocol = MovieRepositoryImpl(),
        socialRepository: SocialRepositoryProtocol = SocialRepositoryImpl(),
        groupRepository: GroupRepositoryProtocol = GroupRepositoryImpl(),
        directChatRepository: DirectChatRepositoryProtocol = DirectChatRepositoryImpl(),
        authService: AuthServiceProtocol = MockAuthService()
    ) {
        self.movieRepository = movieRepository
        self.socialRepository = socialRepository
        self.groupRepository = groupRepository
        self.directChatRepository = directChatRepository
        self.authService = authService
        
        self.authViewModel = AuthViewModel(authService: authService)
        
        self.getNowPlayingUseCase = GetNowPlayingMoviesUseCase(repository: movieRepository)
        self.getClassicsUseCase = GetClassicsMoviesUseCase(repository: movieRepository)
        self.searchMoviesUseCase = SearchMoviesUseCase(repository: movieRepository)
        self.getMovieDetailUseCase = GetMovieDetailUseCase(repository: movieRepository)
        self.getRecommendedMoviesUseCase = GetRecommendedMoviesUseCase(movieRepository: movieRepository, socialRepository: socialRepository)
        
        self.getFriendsActivityUseCase = GetFriendsActivityUseCase(repository: socialRepository)
        self.getFriendsReviewsUseCase = GetFriendsReviewsForMovieUseCase(repository: socialRepository)
        self.getCommunityReviewsUseCase = GetCommunityReviewsUseCase(repository: socialRepository)
        self.submitReviewUseCase = SubmitReviewUseCase(repository: socialRepository)
        self.editReviewUseCase = EditReviewUseCase(repository: socialRepository)
        self.getFriendsListUseCase = GetFriendsListUseCase(repository: socialRepository)
        self.addFriendUseCase = AddFriendUseCase(repository: socialRepository)
        self.removeFriendUseCase = RemoveFriendUseCase(repository: socialRepository)
        self.addCommentToReviewUseCase = AddCommentToReviewUseCase(repository: socialRepository)
        self.toggleLikeReviewUseCase = ToggleLikeReviewUseCase(repository: socialRepository)
        self.toggleHelpfulReviewUseCase = ToggleHelpfulReviewUseCase(repository: socialRepository)
        
        self.getGroupsUseCase = GetGroupsUseCase(repository: groupRepository)
        self.createGroupUseCase = CreateGroupUseCase(repository: groupRepository)
        self.getGroupMessagesUseCase = GetGroupMessagesUseCase(repository: groupRepository)
        self.sendGroupMessageUseCase = SendGroupMessageUseCase(repository: groupRepository)
        self.joinGroupUseCase = JoinGroupUseCase(repository: groupRepository)
        self.joinGroupByInviteCodeUseCase = JoinGroupByInviteCodeUseCase(repository: groupRepository)
        self.addMembersToGroupUseCase = AddMembersToGroupUseCase(repository: groupRepository)
        
        self.getDirectConversationsUseCase = GetDirectConversationsUseCase(repository: directChatRepository)
        self.getOrCreateDirectConversationUseCase = GetOrCreateDirectConversationUseCase(repository: directChatRepository)
        self.getDirectMessagesUseCase = GetDirectMessagesUseCase(repository: directChatRepository)
        self.sendDirectMessageUseCase = SendDirectMessageUseCase(repository: directChatRepository)
        self.markDirectMessagesAsReadUseCase = MarkDirectMessagesAsReadUseCase(repository: directChatRepository)
    }
    
    public func makeMovieCatalogViewModel(initialCity: UserLocation? = nil) -> MovieCatalogViewModel {
        MovieCatalogViewModel(
            getNowPlayingUseCase: getNowPlayingUseCase,
            getClassicsUseCase: getClassicsUseCase,
            searchMoviesUseCase: searchMoviesUseCase,
            getRecommendedMoviesUseCase: getRecommendedMoviesUseCase,
            initialCity: initialCity ?? authViewModel.currentUser?.location
        )
    }
    
    public func makeMovieDetailViewModel(movie: Movie) -> MovieDetailViewModel {
        MovieDetailViewModel(
            movie: movie,
            getMovieDetailUseCase: getMovieDetailUseCase,
            getFriendsReviewsUseCase: getFriendsReviewsUseCase,
            getCommunityReviewsUseCase: getCommunityReviewsUseCase,
            submitReviewUseCase: submitReviewUseCase,
            editReviewUseCase: editReviewUseCase,
            addCommentToReviewUseCase: addCommentToReviewUseCase,
            toggleLikeReviewUseCase: toggleLikeReviewUseCase,
            toggleHelpfulReviewUseCase: toggleHelpfulReviewUseCase,
            addFriendUseCase: addFriendUseCase
        )
    }
    
    public func makeSocialViewModel() -> SocialViewModel {
        SocialViewModel(
            getFriendsActivityUseCase: getFriendsActivityUseCase,
            getFriendsListUseCase: getFriendsListUseCase,
            addFriendUseCase: addFriendUseCase,
            removeFriendUseCase: removeFriendUseCase,
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
            joinGroupUseCase: joinGroupUseCase,
            joinGroupByInviteCodeUseCase: joinGroupByInviteCodeUseCase,
            addMembersToGroupUseCase: addMembersToGroupUseCase,
            getFriendsListUseCase: getFriendsListUseCase,
            searchMoviesUseCase: searchMoviesUseCase
        )
    }
    
    public func makeDirectChatViewModel() -> DirectChatViewModel {
        DirectChatViewModel(
            getDirectConversationsUseCase: getDirectConversationsUseCase,
            getOrCreateDirectConversationUseCase: getOrCreateDirectConversationUseCase,
            getDirectMessagesUseCase: getDirectMessagesUseCase,
            sendDirectMessageUseCase: sendDirectMessageUseCase,
            markDirectMessagesAsReadUseCase: markDirectMessagesAsReadUseCase,
            getFriendsListUseCase: getFriendsListUseCase,
            searchMoviesUseCase: searchMoviesUseCase
        )
    }
    
    public func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            getFriendsListUseCase: getFriendsListUseCase,
            getFriendsActivityUseCase: getFriendsActivityUseCase
        )
    }
}
