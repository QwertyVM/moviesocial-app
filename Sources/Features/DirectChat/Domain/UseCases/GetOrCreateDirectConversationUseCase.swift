import Foundation

public struct GetOrCreateDirectConversationUseCase: Sendable {
    private let repository: DirectChatRepositoryProtocol
    
    public init(repository: DirectChatRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(currentUser: User, friend: Friend) async throws -> DirectConversation {
        try await repository.getOrCreateConversation(currentUser: currentUser, friend: friend)
    }
}

