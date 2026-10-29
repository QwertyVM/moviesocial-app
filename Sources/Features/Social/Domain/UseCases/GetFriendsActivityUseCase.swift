import Foundation

public struct GetFriendsActivityUseCase: Sendable {
    private let repository: SocialRepositoryProtocol
    
    public init(repository: SocialRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> [Review] {
        return try await repository.getFriendsFeed()
    }
}

