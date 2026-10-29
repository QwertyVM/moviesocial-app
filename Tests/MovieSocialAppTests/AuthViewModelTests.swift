import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Auth ViewModel Tests")
struct AuthViewModelTests {
    let viewModel: AuthViewModel
    let mockAuth: MockAuthService
    
    init() {
        let auth = MockAuthService()
        self.mockAuth = auth
        self.viewModel = AuthViewModel(authService: auth)
    }
    
    @Test("Initial State is Unauthenticated")
    func initialStateIsUnauthenticated() {
        #expect(!viewModel.isAuthenticated)
        #expect(viewModel.currentUser == nil)
    }
    
    @Test("Sign In With Apple Succeeds")
    func signInWithAppleSucceeds() async {
        await viewModel.signInWithApple()
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.currentUser?.authProvider == .apple)
        #expect(viewModel.currentUser?.displayName == "Alex Rivera")
    }
    
    @Test("Sign In With Google Succeeds")
    func signInWithGoogleSucceeds() async {
        await viewModel.signInWithGoogle()
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.currentUser?.authProvider == .google)
        #expect(viewModel.currentUser?.displayName == "Sofía Martínez")
    }
    
    @Test("Sign Out Clears Session")
    func signOutClearsSession() async {
        await viewModel.signInWithApple()
        #expect(viewModel.isAuthenticated)
        
        await viewModel.signOut()
        #expect(!viewModel.isAuthenticated)
        #expect(viewModel.currentUser == nil)
    }
}
