import Foundation

public struct GetGroupMessagesUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(groupId: String) async throws -> [GroupMessage] {
        try await repository.getGroupMessages(groupId: groupId)
    }
}

