import Foundation

public struct AddMembersToGroupUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(groupId: String, friends: [Friend]) async throws -> MovieGroup {
        try await repository.addMembersToGroup(groupId: groupId, friends: friends)
    }
}

