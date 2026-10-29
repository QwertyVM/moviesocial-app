import Foundation

public struct SendGroupMessageUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(
        groupId: String,
        text: String,
        user: User,
        messageType: GroupMessageType = .text,
        sharedMovieId: String? = nil,
        sharedMovieTitle: String? = nil,
        sharedMoviePosterURL: URL? = nil,
        sharedMovieYear: Int? = nil
    ) async throws -> GroupMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || messageType == .movieShare else {
            throw NSError(domain: "Group", code: 400, userInfo: [NSLocalizedDescriptionKey: "El mensaje no puede estar vacío"])
        }
        return try await repository.sendGroupMessage(
            groupId: groupId,
            text: trimmed,
            user: user,
            messageType: messageType,
            sharedMovieId: sharedMovieId,
            sharedMovieTitle: sharedMovieTitle,
            sharedMoviePosterURL: sharedMoviePosterURL,
            sharedMovieYear: sharedMovieYear
        )
    }
}
