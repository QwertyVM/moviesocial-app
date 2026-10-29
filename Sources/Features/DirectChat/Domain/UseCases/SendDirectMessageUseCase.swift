import Foundation

public struct SendDirectMessageUseCase: Sendable {
    private let repository: DirectChatRepositoryProtocol
    
    public init(repository: DirectChatRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(
        conversationId: String,
        text: String,
        sender: User,
        recipient: Friend,
        messageType: DirectMessageType = .text,
        sharedMovieId: String? = nil,
        sharedMovieTitle: String? = nil,
        sharedMoviePosterURL: URL? = nil,
        sharedMovieYear: Int? = nil
    ) async throws -> DirectMessage {
        try await repository.sendDirectMessage(
            conversationId: conversationId,
            text: text,
            sender: sender,
            recipient: recipient,
            messageType: messageType,
            sharedMovieId: sharedMovieId,
            sharedMovieTitle: sharedMovieTitle,
            sharedMoviePosterURL: sharedMoviePosterURL,
            sharedMovieYear: sharedMovieYear
        )
    }
}

