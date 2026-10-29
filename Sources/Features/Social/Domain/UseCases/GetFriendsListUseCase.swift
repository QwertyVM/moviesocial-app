import Foundation

public struct GetFriendsListUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> [Friend] {
        return try await repository.getFriends()
    }
}

public struct AddFriendUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(username: String) async throws -> Friend {
        return try await repository.addFriend(username: username)
    }
}

