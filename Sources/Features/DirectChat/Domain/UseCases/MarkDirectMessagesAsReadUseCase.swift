import Foundation

public struct MarkDirectMessagesAsReadUseCase: Sendable {
    private let repository: DirectChatRepositoryProtocol
    
    public init(repository: DirectChatRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(conversationId: String, userId: String) async throws {
        try await repository.markAsRead(conversationId: conversationId, userId: userId)
    }
}

