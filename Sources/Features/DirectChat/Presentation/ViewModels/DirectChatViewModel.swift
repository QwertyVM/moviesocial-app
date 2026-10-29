import Foundation
import Observation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Observable
public final class DirectChatViewModel: @unchecked Sendable {
    public var conversations: [DirectConversation] = []
    public var selectedConversation: DirectConversation?
    public var currentMessages: [DirectMessage] = []
    public var isLoading: Bool = false
    public var isLoadingMessages: Bool = false
    public var errorMessage: String?
    public var toastMessage: String?
    
    // MARK: - Direct Chat Management & New Chat
    public var searchQuery: String = ""
    public var isStartingNewChat: Bool = false
    public var allFriends: [Friend] = []
    public var friendSearchQuery: String = ""
    
    // MARK: - Message Input & Movie Sharing
    public var newMessageText: String = ""
    public var isSharingMovieSheetPresented: Bool = false
    public var movieSearchQuery: String = ""
    public var movieSearchResults: [Movie] = []
    public var isSearchingMovies: Bool = false
    public var shareCommentText: String = ""
    
    // MARK: - Dependencies
    private let getDirectConversationsUseCase: GetDirectConversationsUseCase
    private let getOrCreateDirectConversationUseCase: GetOrCreateDirectConversationUseCase
    private let getDirectMessagesUseCase: GetDirectMessagesUseCase
    private let sendDirectMessageUseCase: SendDirectMessageUseCase
    private let markDirectMessagesAsReadUseCase: MarkDirectMessagesAsReadUseCase
    private let getFriendsListUseCase: GetFriendsListUseCase?
    private let searchMoviesUseCase: SearchMoviesUseCase?
    
    public init(
        getDirectConversationsUseCase: GetDirectConversationsUseCase,
        getOrCreateDirectConversationUseCase: GetOrCreateDirectConversationUseCase,
        getDirectMessagesUseCase: GetDirectMessagesUseCase,
        sendDirectMessageUseCase: SendDirectMessageUseCase,
        markDirectMessagesAsReadUseCase: MarkDirectMessagesAsReadUseCase,
        getFriendsListUseCase: GetFriendsListUseCase? = nil,
        searchMoviesUseCase: SearchMoviesUseCase? = nil
    ) {
        self.getDirectConversationsUseCase = getDirectConversationsUseCase
        self.getOrCreateDirectConversationUseCase = getOrCreateDirectConversationUseCase
        self.getDirectMessagesUseCase = getDirectMessagesUseCase
        self.sendDirectMessageUseCase = sendDirectMessageUseCase
        self.markDirectMessagesAsReadUseCase = markDirectMessagesAsReadUseCase
        self.getFriendsListUseCase = getFriendsListUseCase
        self.searchMoviesUseCase = searchMoviesUseCase
    }
    
    // MARK: - Computed Properties
    
    public var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }
    
    public var filteredConversations: [DirectConversation] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return conversations
        }
        return conversations.filter {
            $0.participant.displayName.lowercased().contains(q) ||
            $0.participant.username.lowercased().contains(q) ||
            ($0.lastMessage?.text.lowercased().contains(q) ?? false)
        }
    }
    
    public var filteredFriends: [Friend] {
        let q = friendSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return allFriends
        }
        return allFriends.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q)
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    public func loadConversations(userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            conversations = try await getDirectConversationsUseCase.execute(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func selectConversation(_ conversation: DirectConversation, currentUserId: String) async {
        selectedConversation = conversation
        isLoadingMessages = true
        do {
            currentMessages = try await getDirectMessagesUseCase.execute(conversationId: conversation.id)
            try await markDirectMessagesAsReadUseCase.execute(conversationId: conversation.id, userId: currentUserId)
            
            // Reflejar localmente estado leído
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[index].unreadCount = 0
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMessages = false
    }
    
    @MainActor
    public func startChatWithFriend(_ friend: Friend, currentUser: User) async -> DirectConversation? {
        do {
            let conv = try await getOrCreateDirectConversationUseCase.execute(currentUser: currentUser, friend: friend)
            if !conversations.contains(where: { $0.id == conv.id }) {
                conversations.insert(conv, at: 0)
            }
            await selectConversation(conv, currentUserId: currentUser.id)
            isStartingNewChat = false
            return conv
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    @MainActor
    public func sendMessage(currentUser: User) async -> Bool {
        guard let conv = selectedConversation else { return false }
        let trimmed = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        do {
            let newMsg = try await sendDirectMessageUseCase.execute(
                conversationId: conv.id,
                text: trimmed,
                sender: currentUser,
                recipient: conv.participant,
                messageType: .text
            )
            
            currentMessages.append(newMsg)
            newMessageText = ""
            
            // Actualizar resumen en la lista
            if let index = conversations.firstIndex(where: { $0.id == conv.id }) {
                conversations[index].lastMessage = newMsg
                conversations[index].updatedAt = newMsg.createdAt
                let updated = conversations.remove(at: index)
                conversations.insert(updated, at: 0)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func shareMovieInChat(movie: Movie, note: String, currentUser: User) async -> Bool {
        guard let conv = selectedConversation else { return false }
        
        do {
            let newMsg = try await sendDirectMessageUseCase.execute(
                conversationId: conv.id,
                text: note.trimmingCharacters(in: .whitespacesAndNewlines),
                sender: currentUser,
                recipient: conv.participant,
                messageType: .movieShare,
                sharedMovieId: movie.id,
                sharedMovieTitle: movie.title,
                sharedMoviePosterURL: movie.posterURL,
                sharedMovieYear: movie.releaseYear
            )
            
            currentMessages.append(newMsg)
            isSharingMovieSheetPresented = false
            shareCommentText = ""
            movieSearchQuery = ""
            movieSearchResults = []
            
            if let index = conversations.firstIndex(where: { $0.id == conv.id }) {
                conversations[index].lastMessage = newMsg
                conversations[index].updatedAt = newMsg.createdAt
                let updated = conversations.remove(at: index)
                conversations.insert(updated, at: 0)
            }
            
            showToast("Película compartida en el chat")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func searchMovies() async {
        guard let searchUseCase = searchMoviesUseCase else { return }
        let query = movieSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            movieSearchResults = []
            return
        }
        
        isSearchingMovies = true
        do {
            movieSearchResults = try await searchUseCase.execute(query: query)
        } catch {
            movieSearchResults = []
        }
        isSearchingMovies = false
    }
    
    @MainActor
    public func loadFriends() async {
        guard let getFriends = getFriendsListUseCase else { return }
        do {
            allFriends = try await getFriends.execute()
        } catch {
            // Mantener lista existente si falla
        }
    }
    
    public func showToast(_ message: String) {
        toastMessage = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                self?.toastMessage = nil
            }
        }
    }
}

