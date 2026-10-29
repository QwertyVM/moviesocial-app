import Foundation

public protocol AuthServiceProtocol: Sendable {
    func signInWithApple() async throws -> User
    func signInWithGoogle() async throws -> User
    func signOut() async throws
    func getCurrentUser() async -> User?
}

