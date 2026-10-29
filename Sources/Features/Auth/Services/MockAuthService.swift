import Foundation

public final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    private var currentUser: User?
    private let database: AppDatabase
    
    public init(initialUser: User? = nil, database: AppDatabase = AppDatabase.shared) {
        self.currentUser = initialUser
        self.database = database
    }
    
    public func signInWithApple() async throws -> User {
        let user = User(
            id: "apple_user_101",
            email: "cinefilo@apple.com",
            displayName: "Alex Rivera",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200"),
            authProvider: .apple
        )
        self.currentUser = user
        await database.saveUser(user)
        await database.saveCurrentSessionUserId(user.id)
        return user
    }
    
    public func signInWithGoogle() async throws -> User {
        let user = User(
            id: "google_user_202",
            email: "sofia.movies@gmail.com",
            displayName: "Sofía Martínez",
            avatarURL: URL(string: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200"),
            authProvider: .google
        )
        self.currentUser = user
        await database.saveUser(user)
        await database.saveCurrentSessionUserId(user.id)
        return user
    }
    
    public func signOut() async throws {
        self.currentUser = nil
        await database.saveCurrentSessionUserId(nil)
    }
    
    public func getCurrentUser() async -> User? {
        if let currentUser {
            return currentUser
        }
        if let sessionId = await database.getCurrentSessionUserId(),
           let persistedUser = await database.getUser(id: sessionId) {
            self.currentUser = persistedUser
            return persistedUser
        }
        return nil
    }
}

