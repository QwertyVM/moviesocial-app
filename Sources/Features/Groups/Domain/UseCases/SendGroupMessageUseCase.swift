import Foundation

public struct SendGroupMessageUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(groupId: String, text: String, user: User) async throws -> GroupMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "Group", code: 400, userInfo: [NSLocalizedDescriptionKey: "El mensaje no puede estar vacío"])
        }
        return try await repository.sendGroupMessage(groupId: groupId, text: trimmed, user: user)
    }
}

