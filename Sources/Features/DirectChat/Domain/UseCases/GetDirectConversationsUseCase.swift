import Foundation

public struct GetDirectConversationsUseCase: Sendable {
    private let repository: DirectChatRepositoryProtocol
    
    public init(repository: DirectChatRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(userId: String) async throws -> [DirectConversation] {
        try await repository.getConversations(userId: userId)
    }
}

