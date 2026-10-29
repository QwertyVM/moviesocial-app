import Foundation

public protocol DirectChatRepositoryProtocol: Sendable {
    func getConversations(userId: String) async throws -> [DirectConversation]
    func getConversation(id: String) async throws -> DirectConversation?
    func getOrCreateConversation(currentUser: User, friend: Friend) async throws -> DirectConversation
    func getMessages(conversationId: String) async throws -> [DirectMessage]
    func sendDirectMessage(
        conversationId: String,
        text: String,
        sender: User,
        recipient: Friend,
        messageType: DirectMessageType,
        sharedMovieId: String?,
        sharedMovieTitle: String?,
        sharedMoviePosterURL: URL?,
        sharedMovieYear: Int?
    ) async throws -> DirectMessage
    func markAsRead(conversationId: String, userId: String) async throws
}

public extension DirectChatRepositoryProtocol {
    func sendDirectMessage(
        conversationId: String,
        text: String,
        sender: User,
        recipient: Friend
    ) async throws -> DirectMessage {
        try await sendDirectMessage(
            conversationId: conversationId,
            text: text,
            sender: sender,
            recipient: recipient,
            messageType: .text,
            sharedMovieId: nil,
            sharedMovieTitle: nil,
            sharedMoviePosterURL: nil,
            sharedMovieYear: nil
        )
    }
}

