import Testing
import Foundation
@testable import MovieSocialApp

@Suite("SQLite Database & Persistence Engine Tests")
struct AppDatabaseTests {
    
    // MARK: - InMemory DB Initialization & Stats
    
    @Test("AppDatabase initializes in-memory database with tables created")
    func testDatabaseInitialization() async {
        let db = AppDatabase(inMemory: true)
        let stats = await db.getDatabaseStats()
        
        #expect(stats["users"] == 0)
        #expect(stats["friends"] == 0)
        #expect(stats["reviews"] == 0)
        #expect(stats["direct_conversations"] == 0)
        #expect(stats["movie_groups"] == 0)
    }
    
    // MARK: - User Session Persistence
    
    @Test("AppDatabase persists user session and retrieves user")
    func testUserSessionPersistence() async {
        let db = AppDatabase(inMemory: true)
        
        let testUser = User(
            id: "user_test_42",
            email: "test@moviesocial.app",
            displayName: "Cinéfalo Experto",
            username: "@cinexperto",
            bio: "Amante del cine de autor y noir",
            authProvider: .apple
        )
        
        await db.saveUser(testUser)
        await db.saveCurrentSessionUserId(testUser.id)
        
        let sessionUserId = await db.getCurrentSessionUserId()
        #expect(sessionUserId == "user_test_42")
        
        let fetchedUser = await db.getUser(id: "user_test_42")
        #expect(fetchedUser != nil)
        #expect(fetchedUser?.displayName == "Cinéfalo Experto")
        #expect(fetchedUser?.username == "@cinexperto")
        #expect(fetchedUser?.email == "test@moviesocial.app")
        
        // Limpiar sesión
        await db.saveCurrentSessionUserId(nil)
        let clearedSession = await db.getCurrentSessionUserId()
        #expect(clearedSession == nil)
    }
    
    // MARK: - Reviews Persistence
    
    @Test("AppDatabase persists and queries reviews by movie and user")
    func testReviewsPersistence() async {
        let db = AppDatabase(inMemory: true)
        
        let review1 = Review(
            id: "rev_1",
            userId: "u1",
            userName: "Carlos",
            movieId: "movie_ekeko",
            movieTitle: "Ekeko",
            rating: 8.5,
            comment: "Excelente ambientación andina.",
            createdAt: Date()
        )
        
        let review2 = Review(
            id: "rev_2",
            userId: "u2",
            userName: "Valeria",
            movieId: "movie_ekeko",
            movieTitle: "Ekeko",
            rating: 9.0,
            comment: "Una joya del terror peruano.",
            createdAt: Date().addingTimeInterval(60)
        )
        
        await db.saveReview(review1, isCommunity: false)
        await db.saveReview(review2, isCommunity: false)
        
        let ekekoReviews = await db.getReviewsForMovie(movieId: "movie_ekeko")
        #expect(ekekoReviews.count == 2)
        #expect(ekekoReviews.contains(where: { $0.id == "rev_1" }))
        #expect(ekekoReviews.contains(where: { $0.id == "rev_2" }))
        
        let user1Reviews = await db.getUserReviews(userId: "u1")
        #expect(user1Reviews.count == 1)
        #expect(user1Reviews.first?.userName == "Carlos")
    }
    
    // MARK: - Direct Chat Persistence
    
    @Test("AppDatabase persists conversations and direct messages")
    func testDirectChatPersistence() async {
        let db = AppDatabase(inMemory: true)
        
        let friend = Friend(
            id: "friend_lucas",
            displayName: "Lucas",
            username: "@lucas",
            avatarURL: nil
        )
        
        let conv = DirectConversation(
            id: "conv_lucas",
            participant: friend,
            lastMessage: nil,
            unreadCount: 1,
            updatedAt: Date()
        )
        
        await db.saveConversation(conv)
        let allConvs = await db.getAllConversations()
        #expect(allConvs.count == 1)
        #expect(allConvs.first?.participant.displayName == "Lucas")
        
        let message = DirectMessage(
            id: "msg_1",
            conversationId: "conv_lucas",
            senderId: "friend_lucas",
            senderName: "Lucas",
            recipientId: "user_me",
            text: "¿Ya viste Ekeko en Cineplanet?",
            createdAt: Date()
        )
        
        await db.saveDirectMessage(message)
        let messages = await db.getDirectMessages(conversationId: "conv_lucas")
        #expect(messages.count == 1)
        #expect(messages.first?.text == "¿Ya viste Ekeko en Cineplanet?")
    }
    
    // MARK: - Movie Groups Persistence
    
    @Test("AppDatabase persists cineclub groups and group messages")
    func testMovieGroupsPersistence() async {
        let db = AppDatabase(inMemory: true)
        
        let group = MovieGroup(
            id: "grp_cine_latino",
            name: "Cinefilia Latinoamericana",
            description: "Debates semanales",
            iconEmoji: "🎬",
            creatorId: "user_admin",
            creatorName: "Admin",
            members: [],
            inviteCode: "CINE-LATAM",
            createdAt: Date()
        )
        
        await db.saveGroup(group)
        let allGroups = await db.getAllGroups()
        #expect(allGroups.count == 1)
        #expect(allGroups.first?.name == "Cinefilia Latinoamericana")
        
        let grpMsg = GroupMessage(
            id: "grp_msg_1",
            groupId: "grp_cine_latino",
            userId: "user_admin",
            userName: "Admin",
            text: "¡Bienvenidos a todos al cineclub!",
            createdAt: Date()
        )
        
        await db.saveGroupMessage(grpMsg)
        let groupMsgs = await db.getGroupMessages(groupId: "grp_cine_latino")
        #expect(groupMsgs.count == 1)
        #expect(groupMsgs.first?.text == "¡Bienvenidos a todos al cineclub!")
    }
    
    // MARK: - Clear All Tables Maintenance
    
    @Test("AppDatabase clearAllTables removes records and resets tables")
    func testClearAllTables() async {
        let db = AppDatabase(inMemory: true)
        
        let friend = Friend(id: "f1", displayName: "F1", username: "@f1", avatarURL: nil)
        await db.saveFriend(friend)
        
        var stats = await db.getDatabaseStats()
        #expect(stats["friends"] == 1)
        
        await db.clearAllTables()
        
        stats = await db.getDatabaseStats()
        #expect(stats["friends"] == 0)
        #expect(stats["reviews"] == 0)
    }
}
