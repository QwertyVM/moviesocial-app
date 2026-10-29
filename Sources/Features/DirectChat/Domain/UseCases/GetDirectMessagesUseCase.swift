import Foundation

public struct GetDirectMessagesUseCase: Sendable {
    private let repository: DirectChatRepositoryProtocol
    
    public init(repository: DirectChatRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(conversationId: String) async throws -> [DirectMessage] {
        try await repository.getMessages(conversationId: conversationId)
    }
}

