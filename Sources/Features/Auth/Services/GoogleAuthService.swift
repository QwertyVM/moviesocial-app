import Foundation

public final class GoogleAuthService: AuthServiceProtocol, @unchecked Sendable {
    private var currentUser: User?
    
    public init() {}
    
    public func signInWithApple() async throws -> User {
        throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Use AppleAuthService for Apple Login"])
    }
    
    public func signInWithGoogle() async throws -> User {
        // En producción se vincula con GIDSignIn.sharedInstance.signIn
        let user = User(
            id: "google_auth_\(UUID().uuidString.prefix(8))",
            email: "cinefilo.google@gmail.com",
            displayName: "Cineasta Google",
            avatarURL: URL(string: "https://lh3.googleusercontent.com/a/default-user=s96-c"),
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

