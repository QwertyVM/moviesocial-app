import Foundation

public protocol GroupRepositoryProtocol: Sendable {
    func getGroups() async throws -> [MovieGroup]
    func getGroup(id: String) async throws -> MovieGroup?
    func createGroup(
        name: String,
        description: String,
        iconEmoji: String,
        currentMovieId: String?,
        currentMovieTitle: String?,
        currentMoviePosterURL: URL?,
        currentMovieYear: Int?,
        creator: User
    ) async throws -> MovieGroup
    func joinGroup(groupId: String, user: User) async throws -> MovieGroup
    func getGroupMessages(groupId: String) async throws -> [GroupMessage]
    func sendGroupMessage(groupId: String, text: String, user: User) async throws -> GroupMessage
    func setGroupMovie(groupId: String, movie: Movie) async throws -> MovieGroup
}

