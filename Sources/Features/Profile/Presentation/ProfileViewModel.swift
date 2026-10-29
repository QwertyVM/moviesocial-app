import Foundation
import Observation

@Observable
public final class ProfileViewModel: @unchecked Sendable {
    public var friendsCount: Int = 0
    public var userReviewsCount: Int = 0
    public var averageGivenRating: Double = 0.0
    public var friends: [Friend] = []
    public var isLoading: Bool = false
    
    private let getFriendsListUseCase: GetFriendsListUseCase
    private let getFriendsActivityUseCase: GetFriendsActivityUseCase
    
    public init(
        getFriendsListUseCase: GetFriendsListUseCase,
        getFriendsActivityUseCase: GetFriendsActivityUseCase
    ) {
        self.getFriendsListUseCase = getFriendsListUseCase
        self.getFriendsActivityUseCase = getFriendsActivityUseCase
    }
    
    @MainActor
    public func loadProfileData(user: User) async {
        isLoading = true
        do {
            let friendList = try await getFriendsListUseCase.execute()
            let allReviews = try await getFriendsActivityUseCase.execute()
            
            let userReviews = allReviews.filter { $0.userId == user.id }
            
            self.friends = friendList
            self.friendsCount = friendList.count
            self.userReviewsCount = userReviews.count
            if !userReviews.isEmpty {
                self.averageGivenRating = userReviews.reduce(0.0) { $0 + $1.rating } / Double(userReviews.count)
            } else {
                self.averageGivenRating = 4.8
            }
        } catch {
            // handle silently
        }
        isLoading = false
    }
}

