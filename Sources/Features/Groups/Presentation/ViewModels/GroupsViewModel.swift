import Foundation
import Observation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Observable
public final class GroupsViewModel: @unchecked Sendable {
    public var groups: [MovieGroup] = []
    public var selectedGroup: MovieGroup?
    public var currentGroupMessages: [GroupMessage] = []
    public var isLoading: Bool = false
    public var isLoadingMessages: Bool = false
    public var errorMessage: String?
    public var toastMessage: String?
    
    // MARK: - Group Creation (WhatsApp 2-Step Flow)
    public var isCreatingGroup: Bool = false
    public var createStep: Int = 0 // 0: Añadir amigos, 1: Asunto y enlace de invitación
    public var allFriends: [Friend] = []
    public var friendSearchQuery: String = ""
    public var selectedFriendIds: Set<String> = []
    public var newGroupName: String = ""
    public var newGroupDescription: String = ""
    public var selectedEmoji: String = "🎬"
    public var newGroupMovieTitle: String = ""
    public var generatedInviteCode: String = ""
    
    // MARK: - Join via Invite Link / Code
    public var isJoiningViaLink: Bool = false
    public var inviteLinkOrCodeInput: String = ""
    
    // MARK: - Group Info & Member Management
    public var isViewingGroupInfo: Bool = false
    public var isAddingMembersSheetPresented: Bool = false
    public var selectedFriendsToAddIds: Set<String> = []
    
    // MARK: - Chat & Media Sharing
    public var newMessageText: String = ""
    public var isSharingMovieSheetPresented: Bool = false
    public var movieSearchQuery: String = ""
    public var movieSearchResults: [Movie] = []
    public var isSearchingMovies: Bool = false
    
    // MARK: - Dependencies
    private let getGroupsUseCase: GetGroupsUseCase
    private let createGroupUseCase: CreateGroupUseCase
    private let getGroupMessagesUseCase: GetGroupMessagesUseCase
    private let sendGroupMessageUseCase: SendGroupMessageUseCase
    private let joinGroupUseCase: JoinGroupUseCase
    private let joinGroupByInviteCodeUseCase: JoinGroupByInviteCodeUseCase?
    private let addMembersToGroupUseCase: AddMembersToGroupUseCase?
    private let getFriendsListUseCase: GetFriendsListUseCase?
    private let searchMoviesUseCase: SearchMoviesUseCase?
    
    public init(
        getGroupsUseCase: GetGroupsUseCase,
        createGroupUseCase: CreateGroupUseCase,
        getGroupMessagesUseCase: GetGroupMessagesUseCase,
        sendGroupMessageUseCase: SendGroupMessageUseCase,
        joinGroupUseCase: JoinGroupUseCase,
        joinGroupByInviteCodeUseCase: JoinGroupByInviteCodeUseCase? = nil,
        addMembersToGroupUseCase: AddMembersToGroupUseCase? = nil,
        getFriendsListUseCase: GetFriendsListUseCase? = nil,
        searchMoviesUseCase: SearchMoviesUseCase? = nil
    ) {
        self.getGroupsUseCase = getGroupsUseCase
        self.createGroupUseCase = createGroupUseCase
        self.getGroupMessagesUseCase = getGroupMessagesUseCase
        self.sendGroupMessageUseCase = sendGroupMessageUseCase
        self.joinGroupUseCase = joinGroupUseCase
        self.joinGroupByInviteCodeUseCase = joinGroupByInviteCodeUseCase
        self.addMembersToGroupUseCase = addMembersToGroupUseCase
        self.getFriendsListUseCase = getFriendsListUseCase
        self.searchMoviesUseCase = searchMoviesUseCase
    }
    
    // MARK: - Computed Properties
    
    public var filteredFriends: [Friend] {
        let query = friendSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return allFriends
        }
        return allFriends.filter {
            $0.displayName.lowercased().contains(query) ||
            $0.username.lowercased().contains(query)
        }
    }
    
    public var selectedFriends: [Friend] {
        allFriends.filter { selectedFriendIds.contains($0.id) }
    }
    
    public var generatedInviteLink: String {
        "https://moviesocial.app/join/\(generatedInviteCode)"
    }
    
    // MARK: - Actions
    
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
    public func loadFriends() async {
        guard let getFriendsListUseCase else { return }
        do {
            self.allFriends = try await getFriendsListUseCase.execute()
        } catch {
            // Silencioso o log
        }
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
            let msg = try await sendGroupMessageUseCase.execute(
                groupId: group.id,
                text: text,
                user: user,
                messageType: .text,
                sharedMovieId: nil,
                sharedMovieTitle: nil,
                sharedMoviePosterURL: nil,
                sharedMovieYear: nil
            )
            self.currentGroupMessages.append(msg)
            self.newMessageText = ""
            
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
    public func shareMovie(movie: Movie, note: String?, user: User) async -> Bool {
        guard let group = selectedGroup else { return false }
        let text = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let displayText = text.isEmpty ? "Recomiendo ver esta película: «\(movie.title)»" : text
        
        do {
            let msg = try await sendGroupMessageUseCase.execute(
                groupId: group.id,
                text: displayText,
                user: user,
                messageType: .movieShare,
                sharedMovieId: movie.id,
                sharedMovieTitle: movie.title,
                sharedMoviePosterURL: movie.posterURL,
                sharedMovieYear: movie.releaseYear
            )
            self.currentGroupMessages.append(msg)
            self.isSharingMovieSheetPresented = false
            self.movieSearchQuery = ""
            self.movieSearchResults = []
            
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
    public func searchMovies(query: String) async {
        guard let searchMoviesUseCase else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            self.movieSearchResults = []
            return
        }
        
        isSearchingMovies = true
        do {
            self.movieSearchResults = try await searchMoviesUseCase.execute(query: trimmed)
        } catch {
            self.movieSearchResults = []
        }
        isSearchingMovies = false
    }
    
    // MARK: - Creation Flow Helpers
    
    @MainActor
    public func startGroupCreation() {
        self.createStep = 0
        self.selectedFriendIds.removeAll()
        self.friendSearchQuery = ""
        self.newGroupName = ""
        self.newGroupDescription = ""
        self.selectedEmoji = "🎬"
        self.newGroupMovieTitle = ""
        self.generatedInviteCode = "CINE-\(UUID().uuidString.prefix(6).uppercased())"
        self.isCreatingGroup = true
        
        Task {
            await loadFriends()
        }
    }
    
    public func toggleFriendSelection(friendId: String) {
        if selectedFriendIds.contains(friendId) {
            selectedFriendIds.remove(friendId)
        } else {
            selectedFriendIds.insert(friendId)
        }
    }
    
    public func removeSelectedFriend(friendId: String) {
        selectedFriendIds.remove(friendId)
    }
    
    public func proceedToDetailsStep() {
        self.createStep = 1
    }
    
    @MainActor
    public func createGroup(creator: User) async -> Bool {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        
        isLoading = true
        do {
            let movieTitle = newGroupMovieTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let chosenFriends = selectedFriends
            
            let newGroup = try await createGroupUseCase.execute(
                name: name,
                description: newGroupDescription,
                iconEmoji: selectedEmoji,
                initialMembers: chosenFriends,
                currentMovieId: nil,
                currentMovieTitle: movieTitle.isEmpty ? nil : movieTitle,
                currentMoviePosterURL: nil,
                currentMovieYear: nil,
                creator: creator
            )
            
            self.groups.insert(newGroup, at: 0)
            self.selectedGroup = newGroup
            await self.loadMessages(for: newGroup.id)
            
            self.isCreatingGroup = false
            self.isLoading = false
            showToast("¡Cineclub «\(name)» creado con éxito!")
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return false
        }
    }
    
    // MARK: - Join via Link / Code
    
    @MainActor
    public func joinGroupByCode(user: User) async -> Bool {
        guard let joinGroupByInviteCodeUseCase else { return false }
        let code = inviteLinkOrCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return false }
        
        isLoading = true
        errorMessage = nil
        do {
            let joinedGroup = try await joinGroupByInviteCodeUseCase.execute(inviteCodeOrLink: code, user: user)
            
            if let index = groups.firstIndex(where: { $0.id == joinedGroup.id }) {
                groups[index] = joinedGroup
            } else {
                groups.insert(joinedGroup, at: 0)
            }
            
            self.selectedGroup = joinedGroup
            await self.loadMessages(for: joinedGroup.id)
            
            self.inviteLinkOrCodeInput = ""
            self.isJoiningViaLink = false
            self.isLoading = false
            showToast("¡Te has unido a «\(joinedGroup.name)»!")
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
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
            await self.loadMessages(for: groupId)
            showToast("¡Te has unido al cineclub!")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Member Addition to Existing Group
    
    @MainActor
    public func addFriendsToCurrentGroup(user: User) async -> Bool {
        guard let group = selectedGroup, let addMembersToGroupUseCase else { return false }
        let friendsToAdd = allFriends.filter { selectedFriendsToAddIds.contains($0.id) }
        guard !friendsToAdd.isEmpty else { return false }
        
        do {
            let updated = try await addMembersToGroupUseCase.execute(groupId: group.id, friends: friendsToAdd)
            if let index = groups.firstIndex(where: { $0.id == group.id }) {
                groups[index] = updated
            }
            self.selectedGroup = updated
            await self.loadMessages(for: group.id)
            
            self.selectedFriendsToAddIds.removeAll()
            self.isAddingMembersSheetPresented = false
            showToast("¡Amigos añadidos al cineclub!")
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Clipboard & Utilities
    
    public func copyInviteLink(for group: MovieGroup) {
        copyToClipboard(group.inviteLink)
        showToast("¡Enlace de invitación copiado al portapapeles!")
    }
    
    public func copyInviteCode(for group: MovieGroup) {
        copyToClipboard(group.inviteCode)
        showToast("Código «\(group.inviteCode)» copiado!")
    }
    
    public func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
    
    public func showToast(_ message: String) {
        self.toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if self.toastMessage == message {
                self.toastMessage = nil
            }
        }
    }
}
