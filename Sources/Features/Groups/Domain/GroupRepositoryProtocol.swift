import Foundation

public protocol GroupRepositoryProtocol: Sendable {
    func getGroups() async throws -> [MovieGroup]
    func getGroup(id: String) async throws -> MovieGroup?
    func createGroup(
        name: String,
        description: String,
        iconEmoji: String,
        initialMembers: [Friend],
        currentMovieId: String?,
        currentMovieTitle: String?,
        currentMoviePosterURL: URL?,
        currentMovieYear: Int?,
        creator: User
    ) async throws -> MovieGroup
    func joinGroup(groupId: String, user: User) async throws -> MovieGroup
    func joinGroupByInviteCode(code: String, user: User) async throws -> MovieGroup
    func addMembersToGroup(groupId: String, friends: [Friend]) async throws -> MovieGroup
    func getGroupMessages(groupId: String) async throws -> [GroupMessage]
    func sendGroupMessage(
        groupId: String,
        text: String,
        user: User,
        messageType: GroupMessageType,
        sharedMovieId: String?,
        sharedMovieTitle: String?,
        sharedMoviePosterURL: URL?,
        sharedMovieYear: Int?
    ) async throws -> GroupMessage
    func setGroupMovie(groupId: String, movie: Movie) async throws -> MovieGroup
}

public extension GroupRepositoryProtocol {
    func createGroup(
        name: String,
        description: String,
        iconEmoji: String,
        currentMovieId: String?,
        currentMovieTitle: String?,
        currentMoviePosterURL: URL?,
        currentMovieYear: Int?,
        creator: User
    ) async throws -> MovieGroup {
        try await createGroup(
            name: name,
            description: description,
            iconEmoji: iconEmoji,
            initialMembers: [],
            currentMovieId: currentMovieId,
            currentMovieTitle: currentMovieTitle,
            currentMoviePosterURL: currentMoviePosterURL,
            currentMovieYear: currentMovieYear,
            creator: creator
        )
    }

    func sendGroupMessage(groupId: String, text: String, user: User) async throws -> GroupMessage {
        try await sendGroupMessage(
            groupId: groupId,
            text: text,
            user: user,
            messageType: .text,
            sharedMovieId: nil,
            sharedMovieTitle: nil,
            sharedMoviePosterURL: nil,
            sharedMovieYear: nil
        )
    }
}
