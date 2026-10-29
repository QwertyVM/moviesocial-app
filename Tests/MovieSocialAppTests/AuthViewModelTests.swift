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
    
    @Test("Edit Profile Updates User Details Successfully")
    @MainActor
    func editProfileUpdatesUserDetailsSuccessfully() async {
        await viewModel.signInWithApple()
        #expect(viewModel.currentUser?.displayName == "Alex Rivera")
        
        viewModel.updateProfile(
            displayName: "Alejandro Rivera",
            username: "@alex_cinema",
            bio: "Adicto al cine de autor y banda sonora en vinilo.",
            favoriteDirector: "Denis Villeneuve",
            favoriteGenre: "Ciencia Ficción",
            avatarEmoji: "🚀",
            city: "Barcelona",
            country: "España",
            flagEmoji: "🇪🇸"
        )
        
        #expect(viewModel.currentUser?.displayName == "Alejandro Rivera")
        #expect(viewModel.currentUser?.username == "@alex_cinema")
        #expect(viewModel.currentUser?.bio == "Adicto al cine de autor y banda sonora en vinilo.")
        #expect(viewModel.currentUser?.favoriteDirector == "Denis Villeneuve")
        #expect(viewModel.currentUser?.favoriteGenre == "Ciencia Ficción")
        #expect(viewModel.currentUser?.avatarEmoji == "🚀")
        #expect(viewModel.currentUser?.location?.city == "Barcelona")
    }
    
    @Test("Edit Profile Formats Username Without At Prefix")
    @MainActor
    func editProfileFormatsUsernameWithoutAtPrefix() async {
        await viewModel.signInWithGoogle()
        
        viewModel.updateProfile(
            displayName: "Sofía Martínez",
            username: "sofiacinefilia",
            bio: "Critica de cine y series",
            favoriteDirector: "Greta Gerwig",
            favoriteGenre: "Drama",
            avatarEmoji: "🍿"
        )
        
        #expect(viewModel.currentUser?.username == "@sofiacinefilia")
    }
    
    @Test("User Location Formatted Text Renders Flag and City Correctly")
    func userLocationFormattedTextRendersProperly() {
        let location = UserLocation(
            city: "Tokio",
            country: "Japón",
            countryCode: "JP",
            flagEmoji: "🇯🇵"
        )
        
        #expect(location.formattedText == "🇯🇵 Tokio, Japón")
    }
}
