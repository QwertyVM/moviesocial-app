import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Edit Profile Feature Tests")
struct EditProfileTests {
    
    @Test("User profile update preserves core identity while changing cinephile metadata")
    func userProfileUpdatePreservesCoreIdentity() {
        let initialUser = User(
            id: "user-123",
            email: "cinefilo@example.com",
            displayName: "Martin S.",
            username: "@martinscorsese",
            bio: "El cine es una cuestión de lo que está dentro del plano y lo que está fuera.",
            favoriteDirector: "Stanley Kubrick",
            favoriteGenre: "Drama",
            avatarEmoji: "🎬",
            authProvider: .apple,
            isPremium: true,
            location: UserLocation(city: "Nueva York", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", isLocal: true)
        )
        
        let newLocation = UserLocation(
            city: "Roma",
            country: "Italia",
            countryCode: "IT",
            flagEmoji: "🇮🇹",
            isLocal: false
        )
        
        let updatedUser = User(
            id: initialUser.id,
            email: initialUser.email,
            displayName: "Martin Scorsese",
            username: "@marty_cine",
            bio: "Explorando la luz, la sombra y el neo-noir en 35mm.",
            favoriteDirector: "Federico Fellini",
            favoriteGenre: "Cine Clásico",
            avatarEmoji: "🎞️",
            avatarURL: initialUser.avatarURL,
            authProvider: initialUser.authProvider,
            createdAt: initialUser.createdAt,
            isPremium: initialUser.isPremium,
            location: newLocation
        )
        
        #expect(updatedUser.id == "user-123")
        #expect(updatedUser.email == "cinefilo@example.com")
        #expect(updatedUser.isPremium == true)
        #expect(updatedUser.displayName == "Martin Scorsese")
        #expect(updatedUser.username == "@marty_cine")
        #expect(updatedUser.favoriteDirector == "Federico Fellini")
        #expect(updatedUser.favoriteGenre == "Cine Clásico")
        #expect(updatedUser.avatarEmoji == "🎞️")
        #expect(updatedUser.location?.formattedText == "🇮🇹 Roma, Italia")
    }
    
    @Test("User location formattedText renders country flag and city correctly")
    func userLocationFormattedTextRendersProperly() {
        let location = UserLocation(
            city: "Barcelona",
            country: "España",
            countryCode: "ES",
            flagEmoji: "🇪🇸"
        )
        
        #expect(location.formattedText == "🇪🇸 Barcelona, España")
    }
    
    @Test("ProfileViewModel loads user reviews, computes review count and average rating accurately")
    func profileViewModelLoadsUserReviewsAccurately() async throws {
        let repo = SocialRepositoryImpl()
        let vm = ProfileViewModel(
            getFriendsListUseCase: GetFriendsListUseCase(repository: repo),
            getFriendsActivityUseCase: GetFriendsActivityUseCase(repository: repo)
        )
        
        let user = User(
            id: "apple_user_101",
            email: "cinefilo@apple.com",
            displayName: "Alex Rivera",
            authProvider: .apple
        )
        
        await vm.loadProfileData(user: user)
        
        #expect(vm.userReviews.count == 2)
        #expect(vm.userReviewsCount == 2)
        #expect(vm.userReviews.contains(where: { $0.movieTitle == "Interstellar" }))
        #expect(vm.userReviews.contains(where: { $0.movieTitle == "El Origen" }))
        #expect(vm.averageGivenRating == 4.75)
    }
    
    @Test("ProfileViewModel handles user with zero reviews without crashing")
    func profileViewModelHandlesUserWithZeroReviews() async throws {
        let repo = SocialRepositoryImpl()
        let vm = ProfileViewModel(
            getFriendsListUseCase: GetFriendsListUseCase(repository: repo),
            getFriendsActivityUseCase: GetFriendsActivityUseCase(repository: repo)
        )
        
        let newUser = User(
            id: "user_brand_new_no_reviews",
            email: "new@apple.com",
            displayName: "Nuevo Usuario",
            authProvider: .apple
        )
        
        await vm.loadProfileData(user: newUser)
        
        #expect(vm.userReviews.isEmpty)
        #expect(vm.userReviewsCount == 0)
        #expect(vm.averageGivenRating == 0.0)
    }
}
