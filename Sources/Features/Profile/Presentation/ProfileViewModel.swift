import Foundation
import Observation

@Observable
public final class ProfileViewModel: @unchecked Sendable {
    public var friendsCount: Int = 0
    public var userReviewsCount: Int = 0
    public var averageGivenRating: Double = 0.0
    public var friends: [Friend] = []
    public var userReviews: [Review] = []
    public var databaseStats: [String: Int] = [:]
    public var isLoading: Bool = false
    public var showResetSuccessAlert: Bool = false
    
    private let getFriendsListUseCase: GetFriendsListUseCase
    private let getFriendsActivityUseCase: GetFriendsActivityUseCase
    private let database: AppDatabase
    
    public init(
        getFriendsListUseCase: GetFriendsListUseCase,
        getFriendsActivityUseCase: GetFriendsActivityUseCase,
        database: AppDatabase = AppDatabase.shared
    ) {
        self.getFriendsListUseCase = getFriendsListUseCase
        self.getFriendsActivityUseCase = getFriendsActivityUseCase
        self.database = database
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
            self.userReviews = userReviews
            self.userReviewsCount = userReviews.count
            if !userReviews.isEmpty {
                self.averageGivenRating = userReviews.reduce(0.0) { $0 + $1.rating } / Double(userReviews.count)
            } else {
                self.averageGivenRating = 0.0
            }
            
            self.databaseStats = await database.getDatabaseStats()
        } catch {
            // handle silently
        }
        isLoading = false
    }
    
    @MainActor
    public func resetDatabase(user: User) async {
        await database.clearAllTables()
        self.databaseStats = await database.getDatabaseStats()
        self.showResetSuccessAlert = true
        await loadProfileData(user: user)
    }
}
