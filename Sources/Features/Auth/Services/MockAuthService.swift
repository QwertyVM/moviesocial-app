import Foundation

public final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    private var currentUser: User?
    
    public init(initialUser: User? = nil) {
        self.currentUser = initialUser
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
        return user
    }
    
    public func signOut() async throws {
        self.currentUser = nil
    }
    
    public func getCurrentUser() async -> User? {
        return currentUser
    }
}

