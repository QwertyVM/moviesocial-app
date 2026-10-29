import Foundation

/// Implementación del repositorio de chats One-to-One utilizando Swift Actor para concurrencia segura
public actor DirectChatRepositoryImpl: DirectChatRepositoryProtocol {
    private var conversations: [DirectConversation]
    private var messages: [String: [DirectMessage]]
    
    public init(
        conversations: [DirectConversation] = defaultConversations,
        messages: [String: [DirectMessage]] = defaultMessages
    ) {
        self.conversations = conversations
        self.messages = messages
    }
    
    public func getConversations(userId: String) async throws -> [DirectConversation] {
        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func getConversation(id: String) async throws -> DirectConversation? {
        return conversations.first { $0.id == id }
    }
    
    public func getOrCreateConversation(currentUser: User, friend: Friend) async throws -> DirectConversation {
        // Buscar conversación existente por id de participante o por formato canon
        if let existing = conversations.first(where: { $0.participant.id == friend.id }) {
            return existing
        }
        
        let conversationId = "conv_\(currentUser.id)_\(friend.id)"
        let newConv = DirectConversation(
            id: conversationId,
            participant: friend,
            lastMessage: nil,
            unreadCount: 0,
            updatedAt: Date()
        )
        
        conversations.insert(newConv, at: 0)
        messages[conversationId] = []
        return newConv
    }
    
    public func getMessages(conversationId: String) async throws -> [DirectMessage] {
        return messages[conversationId] ?? []
    }
    
    public func sendDirectMessage(
        conversationId: String,
        text: String,
        sender: User,
        recipient: Friend,
        messageType: DirectMessageType = .text,
        sharedMovieId: String? = nil,
        sharedMovieTitle: String? = nil,
        sharedMoviePosterURL: URL? = nil,
        sharedMovieYear: Int? = nil
    ) async throws -> DirectMessage {
        let msg = DirectMessage(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: sender.id,
            senderName: sender.displayName,
            senderAvatarURL: sender.avatarURL,
            recipientId: recipient.id,
            text: text,
            messageType: messageType,
            sharedMovieId: sharedMovieId,
            sharedMovieTitle: sharedMovieTitle,
            sharedMoviePosterURL: sharedMoviePosterURL,
            sharedMovieYear: sharedMovieYear,
            isRead: false,
            createdAt: Date()
        )
        
        if messages[conversationId] != nil {
            messages[conversationId]?.append(msg)
        } else {
            messages[conversationId] = [msg]
        }
        
        // Actualizar la conversación
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].lastMessage = msg
            conversations[index].updatedAt = msg.createdAt
            let updated = conversations.remove(at: index)
            conversations.insert(updated, at: 0)
        } else {
            let newConv = DirectConversation(
                id: conversationId,
                participant: recipient,
                lastMessage: msg,
                unreadCount: 0,
                updatedAt: msg.createdAt
            )
            conversations.insert(newConv, at: 0)
        }
        
        return msg
    }
    
    public func markAsRead(conversationId: String, userId: String) async throws {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].unreadCount = 0
        }
        
        if var list = messages[conversationId] {
            for i in 0..<list.count {
                if list[i].recipientId == userId {
                    list[i].isRead = true
                }
            }
            messages[conversationId] = list
        }
    }
    
    // MARK: - Initial Static Seed Data
    
    public static let defaultConversations: [DirectConversation] = [
        DirectConversation(
            id: "conv_default_lucas",
            participant: Friend(
                id: "friend_1",
                displayName: "Lucas Benítez",
                username: "@lucasfilm",
                avatarURL: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200"),
                isMutual: true,
                mutualMoviesCount: 14
            ),
            lastMessage: DirectMessage(
                id: "msg_lucas_3",
                conversationId: "conv_default_lucas",
                senderId: "friend_1",
                senderName: "Lucas Benítez",
                recipientId: "mock_user_1",
                text: "Totalmente de acuerdo, para mí es la película del año. ¿Qué nota le pusiste?",
                messageType: .text,
                isRead: false,
                createdAt: Date().addingTimeInterval(-1800) // 30 min ago
            ),
            unreadCount: 1,
            updatedAt: Date().addingTimeInterval(-1800)
        ),
        DirectConversation(
            id: "conv_default_camila",
            participant: Friend(
                id: "friend_2",
                displayName: "Camila Vega",
                username: "@camicine",
                avatarURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200"),
                isMutual: true,
                mutualMoviesCount: 22
            ),
            lastMessage: DirectMessage(
                id: "msg_camila_2",
                conversationId: "conv_default_camila",
                senderId: "mock_user_1",
                senderName: "Tú",
                recipientId: "friend_2",
                text: "Es una obra maestra absoluta. Tienes que verla con calma y buen sonido.",
                messageType: .text,
                isRead: true,
                createdAt: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            unreadCount: 0,
            updatedAt: Date().addingTimeInterval(-7200)
        ),
        DirectConversation(
            id: "conv_default_mateo",
            participant: Friend(
                id: "friend_3",
                displayName: "Mateo Rossi",
                username: "@mrossi",
                avatarURL: URL(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200"),
                isMutual: true,
                mutualMoviesCount: 8
            ),
            lastMessage: DirectMessage(
                id: "msg_mateo_1",
                conversationId: "conv_default_mateo",
                senderId: "friend_3",
                senderName: "Mateo Rossi",
                recipientId: "mock_user_1",
                text: "¡Hola! ¿Algún clásico de ciencia ficción que me recomiendes para esta noche?",
                messageType: .text,
                isRead: true,
                createdAt: Date().addingTimeInterval(-86400) // 1 day ago
            ),
            unreadCount: 0,
            updatedAt: Date().addingTimeInterval(-86400)
        )
    ]
    
    public static let defaultMessages: [String: [DirectMessage]] = [
        "conv_default_lucas": [
            DirectMessage(
                id: "msg_lucas_1",
                conversationId: "conv_default_lucas",
                senderId: "friend_1",
                senderName: "Lucas Benítez",
                recipientId: "mock_user_1",
                text: "¡Hola! ¿Llegaste a ver la segunda parte de Dune en el cine?",
                messageType: .text,
                isRead: true,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            DirectMessage(
                id: "msg_lucas_movie_share",
                conversationId: "conv_default_lucas",
                senderId: "friend_1",
                senderName: "Lucas Benítez",
                recipientId: "mock_user_1",
                text: "Mira la ficha, las notas de la crítica son una locura",
                messageType: .movieShare,
                sharedMovieId: "693134",
                sharedMovieTitle: "Dune: Parte Dos",
                sharedMoviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
                sharedMovieYear: 2024,
                isRead: true,
                createdAt: Date().addingTimeInterval(-3000)
            ),
            DirectMessage(
                id: "msg_lucas_2",
                conversationId: "conv_default_lucas",
                senderId: "mock_user_1",
                senderName: "Tú",
                recipientId: "friend_1",
                text: "¡Sí! La vi en IMAX el sábado. Increíble el sonido y la fotografía.",
                messageType: .text,
                isRead: true,
                createdAt: Date().addingTimeInterval(-2400)
            ),
            DirectMessage(
                id: "msg_lucas_3",
                conversationId: "conv_default_lucas",
                senderId: "friend_1",
                senderName: "Lucas Benítez",
                recipientId: "mock_user_1",
                text: "Totalmente de acuerdo, para mí es la película del año. ¿Qué nota le pusiste?",
                messageType: .text,
                isRead: false,
                createdAt: Date().addingTimeInterval(-1800)
            )
        ],
        "conv_default_camila": [
            DirectMessage(
                id: "msg_camila_1",
                conversationId: "conv_default_camila",
                senderId: "friend_2",
                senderName: "Camila Vega",
                recipientId: "mock_user_1",
                text: "Tengo pendiente ver El Padrino este fin de semana, vi que le diste 5 estrellas 🍿",
                messageType: .text,
                isRead: true,
                createdAt: Date().addingTimeInterval(-10800)
            ),
            DirectMessage(
                id: "msg_camila_2",
                conversationId: "conv_default_camila",
                senderId: "mock_user_1",
                senderName: "Tú",
                recipientId: "friend_2",
                text: "Es una obra maestra absoluta. Tienes que verla con calma y buen sonido.",
                messageType: .text,
                isRead: true,
                createdAt: Date().addingTimeInterval(-7200)
            )
        ],
        "conv_default_mateo": [
            DirectMessage(
                id: "msg_mateo_1",
                conversationId: "conv_default_mateo",
                senderId: "friend_3",
                senderName: "Mateo Rossi",
                recipientId: "mock_user_1",
                text: "¡Hola! ¿Algún clásico de ciencia ficción que me recomiendes para esta noche?",
                messageType: .text,
                isRead: true,
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]
    ]
}

