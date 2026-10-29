import Foundation
import Observation

public enum SocialFeedFilter: String, CaseIterable, Sendable {
    case all = "Todos"
    case withComments = "Con Comentarios"
}

public enum SocialTabSection: String, CaseIterable, Sendable {
    case feed = "Actividad"
    case friends = "Mis Amigos"
}

@Observable
public final class SocialViewModel: @unchecked Sendable {
    public var feedReviews: [Review] = []
    public var friends: [Friend] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var isAddingFriend: Bool = false
    public var newFriendUsername: String = ""
    public var selectedFilter: SocialFeedFilter = .all
    public var selectedSection: SocialTabSection = .feed
    public var friendSearchText: String = ""
    public var filterFriendId: String? = nil
    public var selectedFriendForDetail: Friend? = nil
    public var activeCommentReview: Review?
    
    private let getFriendsActivityUseCase: GetFriendsActivityUseCase
    private let getFriendsListUseCase: GetFriendsListUseCase
    private let addFriendUseCase: AddFriendUseCase
    private let removeFriendUseCase: RemoveFriendUseCase?
    private let addCommentToReviewUseCase: AddCommentToReviewUseCase
    private let toggleLikeReviewUseCase: ToggleLikeReviewUseCase
    
    public init(
        getFriendsActivityUseCase: GetFriendsActivityUseCase,
        getFriendsListUseCase: GetFriendsListUseCase,
        addFriendUseCase: AddFriendUseCase,
        removeFriendUseCase: RemoveFriendUseCase? = nil,
        addCommentToReviewUseCase: AddCommentToReviewUseCase? = nil,
        toggleLikeReviewUseCase: ToggleLikeReviewUseCase? = nil
    ) {
        self.getFriendsActivityUseCase = getFriendsActivityUseCase
        self.getFriendsListUseCase = getFriendsListUseCase
        self.addFriendUseCase = addFriendUseCase
        self.removeFriendUseCase = removeFriendUseCase
        self.addCommentToReviewUseCase = addCommentToReviewUseCase ?? AddCommentToReviewUseCase(repository: SocialRepositoryImpl())
        self.toggleLikeReviewUseCase = toggleLikeReviewUseCase ?? ToggleLikeReviewUseCase(repository: SocialRepositoryImpl())
    }
    
    public var filteredFriends: [Friend] {
        let query = friendSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let list: [Friend]
        if query.isEmpty {
            list = friends
        } else {
            list = friends.filter {
                $0.displayName.lowercased().contains(query) ||
                $0.username.lowercased().contains(query)
            }
        }
        return list.sorted { first, second in
            if first.isOnline != second.isOnline {
                return first.isOnline && !second.isOnline
            }
            return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
        }
    }
    
    public var onlineFriendsCount: Int {
        friends.filter { $0.isOnline }.count
    }
    
    public var totalMutualMoviesCount: Int {
        friends.reduce(0) { $0 + $1.mutualMoviesCount }
    }
    
    public var activeFilteredFriend: Friend? {
        guard let id = filterFriendId else { return nil }
        return friends.first(where: { $0.id == id })
    }
    
    public var filteredReviews: [Review] {
        var base = feedReviews
        if let filterFriendId = filterFriendId {
            base = base.filter { $0.userId == filterFriendId }
        }
        switch selectedFilter {
        case .all:
            return base
        case .withComments:
            return base.filter { !$0.comments.isEmpty }
        }
    }
    
    public func reviewsForFriend(friendId: String) -> [Review] {
        feedReviews.filter { $0.userId == friendId }
    }
    
    public func clearFriendFilter() {
        filterFriendId = nil
    }
    
    @MainActor
    public func loadSocialFeed() async {
        isLoading = true
        errorMessage = nil
        do {
            async let feed = getFriendsActivityUseCase.execute()
            async let friendList = getFriendsListUseCase.execute()
            
            self.feedReviews = try await feed
            self.friends = try await friendList
            
            // If active review was open, keep it updated
            if let activeId = activeCommentReview?.id {
                self.activeCommentReview = self.feedReviews.first(where: { $0.id == activeId })
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func addFriend() async {
        guard !newFriendUsername.isEmpty else { return }
        isLoading = true
        do {
            let friend = try await addFriendUseCase.execute(username: newFriendUsername)
            self.friends.append(friend)
            self.newFriendUsername = ""
            self.isAddingFriend = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func removeFriend(friendId: String) async {
        friends.removeAll { $0.id == friendId }
        if filterFriendId == friendId {
            filterFriendId = nil
        }
        if selectedFriendForDetail?.id == friendId {
            selectedFriendForDetail = nil
        }
        if let removeFriendUseCase = removeFriendUseCase {
            do {
                try await removeFriendUseCase.execute(friendId: friendId)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    @MainActor
    public func toggleLike(reviewId: String, user: User) async {
        do {
            let result = try await toggleLikeReviewUseCase.execute(reviewId: reviewId, userId: user.id)
            if let index = feedReviews.firstIndex(where: { $0.id == reviewId }) {
                feedReviews[index].isLikedByMe = result.isLiked
                feedReviews[index].likesCount = result.newCount
                if activeCommentReview?.id == reviewId {
                    activeCommentReview = feedReviews[index]
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func addComment(to reviewId: String, text: String, user: User) async -> Bool {
        do {
            let newComment = try await addCommentToReviewUseCase.execute(reviewId: reviewId, text: text, user: user)
            if let index = feedReviews.firstIndex(where: { $0.id == reviewId }) {
                feedReviews[index].comments.append(newComment)
                if activeCommentReview?.id == reviewId {
                    activeCommentReview = feedReviews[index]
                }
            }
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
}
