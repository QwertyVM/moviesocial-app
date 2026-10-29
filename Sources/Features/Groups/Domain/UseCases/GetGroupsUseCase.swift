import Foundation

public struct GetGroupsUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> [MovieGroup] {
        try await repository.getGroups()
    }
}

