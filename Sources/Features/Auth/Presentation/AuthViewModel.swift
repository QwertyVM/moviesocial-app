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
    
    @MainActor
    public func upgradeToPremium() {
        guard let user = currentUser else { return }
        self.currentUser = User(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            username: user.username,
            bio: user.bio,
            favoriteDirector: user.favoriteDirector,
            favoriteGenre: user.favoriteGenre,
            avatarEmoji: user.avatarEmoji,
            avatarURL: user.avatarURL,
            authProvider: user.authProvider,
            createdAt: user.createdAt,
            isPremium: true,
            location: user.location
        )
    }
    
    @MainActor
    public func downgradePremium() {
        guard let user = currentUser else { return }
        self.currentUser = User(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            username: user.username,
            bio: user.bio,
            favoriteDirector: user.favoriteDirector,
            favoriteGenre: user.favoriteGenre,
            avatarEmoji: user.avatarEmoji,
            avatarURL: user.avatarURL,
            authProvider: user.authProvider,
            createdAt: user.createdAt,
            isPremium: false,
            location: user.location
        )
    }
    
    @MainActor
    public func updateProfile(
        displayName: String,
        username: String,
        bio: String,
        favoriteDirector: String,
        favoriteGenre: String,
        avatarEmoji: String,
        city: String = "Madrid",
        country: String = "España",
        flagEmoji: String = "🇪🇸"
    ) {
        guard let user = currentUser else { return }
        
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = trimmedUser.isEmpty ? user.username : (trimmedUser.starts(with: "@") ? trimmedUser : "@\(trimmedUser)")
        
        let newLocation = UserLocation(
            city: city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (user.location?.city ?? "Madrid") : city.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (user.location?.country ?? "España") : country.trimmingCharacters(in: .whitespacesAndNewlines),
            countryCode: user.location?.countryCode ?? "ES",
            flagEmoji: flagEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (user.location?.flagEmoji ?? "🇪🇸") : flagEmoji.trimmingCharacters(in: .whitespacesAndNewlines),
            isLocal: user.location?.isLocal ?? true
        )
        
        self.currentUser = User(
            id: user.id,
            email: user.email,
            displayName: trimmedName.isEmpty ? user.displayName : trimmedName,
            username: cleanUsername,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteDirector: favoriteDirector.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteGenre: favoriteGenre,
            avatarEmoji: avatarEmoji,
            avatarURL: user.avatarURL,
            authProvider: user.authProvider,
            createdAt: user.createdAt,
            isPremium: user.isPremium,
            location: newLocation
        )
    }
}

