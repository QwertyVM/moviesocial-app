import Foundation
import Observation

@Observable
public final class GroupsViewModel: @unchecked Sendable {
    public var groups: [MovieGroup] = []
    public var selectedGroup: MovieGroup?
    public var currentGroupMessages: [GroupMessage] = []
    public var isLoading: Bool = false
    public var isLoadingMessages: Bool = false
    public var errorMessage: String?
    
    // Creation Sheet State
    public var isCreatingGroup: Bool = false
    public var newGroupName: String = ""
    public var newGroupDescription: String = ""
    public var selectedEmoji: String = "🎬"
    public var newGroupMovieTitle: String = ""
    
    // Chat Message State
    public var newMessageText: String = ""
    
    private let getGroupsUseCase: GetGroupsUseCase
    private let createGroupUseCase: CreateGroupUseCase
    private let getGroupMessagesUseCase: GetGroupMessagesUseCase
    private let sendGroupMessageUseCase: SendGroupMessageUseCase
    private let joinGroupUseCase: JoinGroupUseCase
    
    public init(
        getGroupsUseCase: GetGroupsUseCase,
        createGroupUseCase: CreateGroupUseCase,
        getGroupMessagesUseCase: GetGroupMessagesUseCase,
        sendGroupMessageUseCase: SendGroupMessageUseCase,
        joinGroupUseCase: JoinGroupUseCase
    ) {
        self.getGroupsUseCase = getGroupsUseCase
        self.createGroupUseCase = createGroupUseCase
        self.getGroupMessagesUseCase = getGroupMessagesUseCase
        self.sendGroupMessageUseCase = sendGroupMessageUseCase
        self.joinGroupUseCase = joinGroupUseCase
    }
    
    @MainActor
    public func loadGroups() async {
        isLoading = true
        errorMessage = nil
        do {
            self.groups = try await getGroupsUseCase.execute()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func selectGroup(_ group: MovieGroup) async {
        self.selectedGroup = group
        await loadMessages(for: group.id)
    }
    
    @MainActor
    public func loadMessages(for groupId: String) async {
        isLoadingMessages = true
        do {
            self.currentGroupMessages = try await getGroupMessagesUseCase.execute(groupId: groupId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingMessages = false
    }
    
    @MainActor
    public func sendMessage(user: User) async -> Bool {
        guard let group = selectedGroup else { return false }
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        
        do {
            let msg = try await sendGroupMessageUseCase.execute(groupId: group.id, text: text, user: user)
            self.currentGroupMessages.append(msg)
            self.newMessageText = ""
            
            // Actualizar contador en la lista de grupos
            if let index = groups.firstIndex(where: { $0.id == group.id }) {
                groups[index].messagesCount += 1
                selectedGroup = groups[index]
            }
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func createGroup(creator: User) async -> Bool {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        
        isLoading = true
        do {
            let movieTitle = newGroupMovieTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let newGroup = try await createGroupUseCase.execute(
                name: name,
                description: newGroupDescription,
                iconEmoji: selectedEmoji,
                currentMovieId: nil,
                currentMovieTitle: movieTitle.isEmpty ? nil : movieTitle,
                currentMoviePosterURL: nil,
                currentMovieYear: nil,
                creator: creator
            )
            
            self.groups.insert(newGroup, at: 0)
            self.newGroupName = ""
            self.newGroupDescription = ""
            self.selectedEmoji = "🎬"
            self.newGroupMovieTitle = ""
            self.isCreatingGroup = false
            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    @MainActor
    public func joinGroup(groupId: String, user: User) async {
        do {
            let updated = try await joinGroupUseCase.execute(groupId: groupId, user: user)
            if let index = groups.firstIndex(where: { $0.id == groupId }) {
                groups[index] = updated
            }
            if selectedGroup?.id == groupId {
                selectedGroup = updated
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

