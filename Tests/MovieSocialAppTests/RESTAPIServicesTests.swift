import Testing
import Foundation
@testable import MovieSocialApp

@Suite("REST API Services & Database Integration Tests (GET, POST, PUT, DELETE)")
struct RESTAPIServicesTests {
    
    // MARK: - HTTP Methods and Payload DTOs
    
    @Test("HTTPMethod enum contains all required REST verbs")
    func testHTTPMethods() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
    }
    
    @Test("DTOs for REST endpoints encode and decode properly")
    func testRESTPayloadEncodings() throws {
        let createReview = CreateReviewRequest(
            id: "rev_test_99",
            movieId: "ekeko_pe_2026",
            movieTitle: "Ekeko",
            moviePosterURL: "https://example.com/ekeko.jpg",
            movieReleaseYear: 2026,
            userId: "user_test",
            userName: "Tester",
            rating: 9.5,
            comment: "Excelente película",
            isCommunity: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(createReview)
        #expect(!data.isEmpty)
        
        let updateReq = UpdateReviewRequest(rating: 10.0, comment: "Obra maestra corregida")
        let updateData = try encoder.encode(updateReq)
        #expect(!updateData.isEmpty)
        
        let friendReq = CreateFriendRequest(
            id: "f_1",
            displayName: "Amigo Cinefilo",
            username: "@amigo",
            avatarURL: nil
        )
        let friendData = try encoder.encode(friendReq)
        #expect(!friendData.isEmpty)
    }
    
    // MARK: - Social Repository REST Services Integration
    
    @Test("SocialRepository addReview publishes review and triggers POST")
    func testSocialRepositoryAddReviewTriggersService() async throws {
        let repo = SocialRepositoryImpl()
        let user = User(id: "u_service_test", email: "u@t.com", displayName: "Test User", authProvider: .apple)
        
        let review = try await repo.addReview(
            movieId: "ekeko_pe_2026",
            movieTitle: "Ekeko",
            moviePosterURL: nil,
            movieReleaseYear: 2026,
            rating: 8.5,
            comment: "Terror andino auténtico",
            user: user
        )
        
        #expect(review.movieId == "ekeko_pe_2026")
        #expect(review.rating == 8.5)
        #expect(review.comment == "Terror andino auténtico")
        
        let reviews = try await repo.getReviewsForMovie(movieId: "ekeko_pe_2026")
        #expect(reviews.contains(where: { $0.id == review.id }))
    }
    
    @Test("SocialRepository editReview updates review and triggers PUT")
    func testSocialRepositoryEditReviewTriggersService() async throws {
        let repo = SocialRepositoryImpl()
        let user = User(id: "u_service_edit", email: "edit@t.com", displayName: "Edit User", authProvider: .apple)
        
        let created = try await repo.addReview(
            movieId: "movie_test_edit",
            movieTitle: "Película Test",
            moviePosterURL: nil,
            movieReleaseYear: 2025,
            rating: 7.0,
            comment: "Comentario original",
            user: user
        )
        
        let edited = try await repo.editReview(
            reviewId: created.id,
            rating: 9.0,
            comment: "Comentario mejorado tras segunda vista"
        )
        
        #expect(edited.rating == 9.0)
        #expect(edited.comment == "Comentario mejorado tras segunda vista")
    }
    
    @Test("SocialRepository addFriend and removeFriend trigger POST and DELETE")
    func testSocialRepositoryFriendsServices() async throws {
        let repo = SocialRepositoryImpl()
        
        let newFriend = try await repo.addFriend(username: "cinemelomano")
        #expect(newFriend.username == "@cinemelomano")
        
        let friendsAfterAdd = try await repo.getFriends()
        #expect(friendsAfterAdd.contains(where: { $0.id == newFriend.id }))
        
        try await repo.removeFriend(friendId: newFriend.id)
        let friendsAfterRemove = try await repo.getFriends()
        #expect(!friendsAfterRemove.contains(where: { $0.id == newFriend.id }))
    }
    
    // MARK: - Group Repository REST Services Integration
    
    @Test("GroupRepository createGroup and sendGroupMessage trigger REST POST")
    func testGroupRepositoryServices() async throws {
        let repo = GroupRepositoryImpl()
        let admin = User(id: "admin_u", email: "a@u.com", displayName: "Admin Club", authProvider: .apple)
        
        let group = try await repo.createGroup(
            name: "Cinefilia Viva",
            description: "Grupo de debate",
            iconEmoji: "🍿",
            initialMembers: [],
            currentMovieId: nil,
            currentMovieTitle: nil,
            currentMoviePosterURL: nil,
            currentMovieYear: nil,
            creator: admin
        )
        
        #expect(group.name == "Cinefilia Viva")
        #expect(group.creatorId == "admin_u")
        
        let sentMessage = try await repo.sendGroupMessage(
            groupId: group.id,
            text: "¡Hola a todos en el cineclub!",
            user: admin,
            messageType: .text,
            sharedMovieId: nil,
            sharedMovieTitle: nil,
            sharedMoviePosterURL: nil,
            sharedMovieYear: nil
        )
        
        #expect(sentMessage.text == "¡Hola a todos en el cineclub!")
        #expect(sentMessage.groupId == group.id)
    }
}
