import Foundation
import Observation

@Observable
public final class AuthViewModel: @unchecked Sendable {
    public var currentUser: User?
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    
    public init(authService: AuthServiceProtocol = MockAuthService()) {
        self.authService = authService
    }
    
    public var isAuthenticated: Bool {
        currentUser != nil
    }
    
    @MainActor
    public func checkCurrentSession() async {
        self.currentUser = await authService.getCurrentUser()
    }
    
    @MainActor
    public func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        do {
            self.currentUser = try await authService.signInWithApple()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            self.currentUser = try await authService.signInWithGoogle()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    public func signOut() async {
        do {
            try await authService.signOut()
            self.currentUser = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

