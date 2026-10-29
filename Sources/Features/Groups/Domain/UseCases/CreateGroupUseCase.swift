import Foundation

public struct CreateGroupUseCase: Sendable {
    private let repository: GroupRepositoryProtocol
    
    public init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(
        name: String,
        description: String,
        iconEmoji: String = "🎬",
        currentMovieId: String? = nil,
        currentMovieTitle: String? = nil,
        currentMoviePosterURL: URL? = nil,
        currentMovieYear: Int? = nil,
        creator: User
    ) async throws -> MovieGroup {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "Group", code: 400, userInfo: [NSLocalizedDescriptionKey: "El nombre del grupo no puede estar vacío"])
        }
        
        return try await repository.createGroup(
            name: trimmedName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            iconEmoji: iconEmoji,
            currentMovieId: currentMovieId,
            currentMovieTitle: currentMovieTitle,
            currentMoviePosterURL: currentMoviePosterURL,
            currentMovieYear: currentMovieYear,
            creator: creator
        )
    }
}

