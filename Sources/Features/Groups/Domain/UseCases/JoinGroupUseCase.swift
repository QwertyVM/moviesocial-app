import Foundation

public struct JoinGroupUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(groupId: String, user: User) async throws -> MovieGroup {
        try await repository.joinGroup(groupId: groupId, user: user)
    }
}

