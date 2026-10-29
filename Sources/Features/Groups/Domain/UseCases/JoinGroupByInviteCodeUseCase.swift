import Foundation

public struct JoinGroupByInviteCodeUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(inviteCodeOrLink: String, user: User) async throws -> MovieGroup {
        let trimmed = inviteCodeOrLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "Group", code: 400, userInfo: [NSLocalizedDescriptionKey: "El código o enlace no puede estar vacío."])
        }
        return try await repository.joinGroupByInviteCode(code: trimmed, user: user)
    }
}

