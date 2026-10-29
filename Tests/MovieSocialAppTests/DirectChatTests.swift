import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Direct Chat (1-on-1) Tests")
struct DirectChatTests {
    let directRepo: DirectChatRepositoryProtocol
    let getConversationsUseCase: GetDirectConversationsUseCase
    let getOrCreateConversationUseCase: GetOrCreateDirectConversationUseCase
    let getMessagesUseCase: GetDirectMessagesUseCase
    let sendMessageUseCase: SendDirectMessageUseCase
    let markAsReadUseCase: MarkDirectMessagesAsReadUseCase
    
    init() {
        let repo = DirectChatRepositoryImpl()
        self.directRepo = repo
        self.getConversationsUseCase = GetDirectConversationsUseCase(repository: repo)
        self.getOrCreateConversationUseCase = GetOrCreateDirectConversationUseCase(repository: repo)
        self.getMessagesUseCase = GetDirectMessagesUseCase(repository: repo)
        self.sendMessageUseCase = SendDirectMessageUseCase(repository: repo)
        self.markAsReadUseCase = MarkDirectMessagesAsReadUseCase(repository: repo)
    }
    
    @Test("Get Conversations Returns Initial 1-on-1 Preloaded Chats")
    func getConversationsReturnsPreloadedChats() async throws {
        let conversations = try await getConversationsUseCase.execute(userId: "mock_user_1")
        #expect(!conversations.isEmpty)
        #expect(conversations.contains(where: { $0.participant.displayName == "Lucas Benítez" }))
        #expect(conversations.contains(where: { $0.participant.displayName == "Camila Vega" }))
    }
    
    @Test("Start New 1-on-1 Chat With Friend Creates Conversation")
    func startNewChatCreatesConversation() async throws {
        let testUser = User(
            id: "user_cine_tester",
            email: "tester@moviesocial.app",
            displayName: "Cinéfilo Pro",
            authProvider: .apple
        )
        let newFriend = Friend(
            id: "friend_4_sofia",
            displayName: "Sofía Coppola Fan",
            username: "@sofiac",
            isMutual: true,
            mutualMoviesCount: 19
        )
        
        let conv = try await getOrCreateConversationUseCase.execute(currentUser: testUser, friend: newFriend)
        #expect(conv.participant.id == "friend_4_sofia")
        #expect(conv.participant.displayName == "Sofía Coppola Fan")
        #expect(conv.lastMessage == nil)
        
        let allConvs = try await getConversationsUseCase.execute(userId: testUser.id)
        #expect(allConvs.contains(where: { $0.id == conv.id }))
    }
    
    @Test("Starting Chat With Existing Contact Returns Existing Conversation Without Duplicating")
    func startChatWithExistingContactDoesNotDuplicate() async throws {
        let testUser = User(
            id: "mock_user_1",
            email: "user@cine.com",
            displayName: "Tester",
            authProvider: .google
        )
        let existingFriend = Friend(
            id: "friend_1",
            displayName: "Lucas Benítez",
            username: "@lucasfilm"
        )
        
        let conv = try await getOrCreateConversationUseCase.execute(currentUser: testUser, friend: existingFriend)
        #expect(conv.participant.id == "friend_1")
        #expect(conv.id == "conv_default_lucas")
        
        let allConvs = try await getConversationsUseCase.execute(userId: testUser.id)
        let lucasConvs = allConvs.filter { $0.participant.id == "friend_1" }
        #expect(lucasConvs.count == 1)
    }
    
    @Test("Send Text Message in 1-on-1 Chat Updates Conversation And Appends Message")
    func sendMessageInDirectChat() async throws {
        let testUser = User(
            id: "mock_user_1",
            email: "user@cine.com",
            displayName: "Tú",
            authProvider: .apple
        )
        let recipient = Friend(
            id: "friend_2",
            displayName: "Camila Vega",
            username: "@camicine"
        )
        
        let messageText = "¡Qué tal Camila! ¿Viste la última de Villeneuve?"
        let msg = try await sendMessageUseCase.execute(
            conversationId: "conv_default_camila",
            text: messageText,
            sender: testUser,
            recipient: recipient
        )
        
        #expect(msg.text == messageText)
        #expect(msg.senderId == "mock_user_1")
        #expect(msg.recipientId == "friend_2")
        #expect(msg.messageType == .text)
        
        let messages = try await getMessagesUseCase.execute(conversationId: "conv_default_camila")
        #expect(messages.contains(where: { $0.id == msg.id }))
        #expect(messages.last?.text == messageText)
        
        // Verificar que la conversación ahora tiene este mensaje como último mensaje
        let conv = try await directRepo.getConversation(id: "conv_default_camila")
        #expect(conv?.lastMessage?.id == msg.id)
    }
    
    @Test("Send Movie Share Message in 1-on-1 Chat Preserves Movie Metadata")
    func sendMovieShareMessageInDirectChat() async throws {
        let testUser = User(
            id: "mock_user_1",
            email: "user@cine.com",
            displayName: "Tú",
            authProvider: .apple
        )
        let recipient = Friend(
            id: "friend_3",
            displayName: "Mateo Rossi",
            username: "@mrossi"
        )
        
        let msg = try await sendMessageUseCase.execute(
            conversationId: "conv_default_mateo",
            text: "Te recomiendo este clásico indiscutible",
            sender: testUser,
            recipient: recipient,
            messageType: .movieShare,
            sharedMovieId: "238",
            sharedMovieTitle: "El Padrino",
            sharedMoviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            sharedMovieYear: 1972
        )
        
        #expect(msg.messageType == .movieShare)
        #expect(msg.sharedMovieId == "238")
        #expect(msg.sharedMovieTitle == "El Padrino")
        #expect(msg.sharedMovieYear == 1972)
        #expect(msg.text == "Te recomiendo este clásico indiscutible")
        
        let messages = try await getMessagesUseCase.execute(conversationId: "conv_default_mateo")
        #expect(messages.contains(where: { $0.id == msg.id }))
    }
    
    @Test("Mark Messages As Read Resets Unread Count")
    func markMessagesAsRead() async throws {
        // Lucas inicia con 1 mensaje sin leer
        let convBefore = try await directRepo.getConversation(id: "conv_default_lucas")
        #expect(convBefore?.unreadCount == 1)
        
        try await markAsReadUseCase.execute(conversationId: "conv_default_lucas", userId: "mock_user_1")
        
        let convAfter = try await directRepo.getConversation(id: "conv_default_lucas")
        #expect(convAfter?.unreadCount == 0)
    }
    
    @Test("DirectChatViewModel Filters Conversations and Computes Unread")
    @MainActor
    func directChatViewModelFilteringAndUnread() async throws {
        let vm = DirectChatViewModel(
            getDirectConversationsUseCase: getConversationsUseCase,
            getOrCreateDirectConversationUseCase: getOrCreateConversationUseCase,
            getDirectMessagesUseCase: getMessagesUseCase,
            sendDirectMessageUseCase: sendMessageUseCase,
            markDirectMessagesAsReadUseCase: markAsReadUseCase
        )
        
        await vm.loadConversations(userId: "mock_user_1")
        #expect(vm.conversations.count >= 3)
        #expect(vm.totalUnreadCount >= 1)
        
        // Filtro por nombre
        vm.searchQuery = "Lucas"
        #expect(vm.filteredConversations.count == 1)
        #expect(vm.filteredConversations.first?.participant.displayName == "Lucas Benítez")
        
        // Filtro por @usuario
        vm.searchQuery = "@camicine"
        #expect(vm.filteredConversations.count == 1)
        #expect(vm.filteredConversations.first?.participant.displayName == "Camila Vega")
        
        // Filtro sin coincidencias
        vm.searchQuery = "NonExistentPersonXYZ"
        #expect(vm.filteredConversations.isEmpty)
        
        // Limpiar filtro
        vm.searchQuery = ""
        #expect(vm.filteredConversations.count == vm.conversations.count)
    }
}

