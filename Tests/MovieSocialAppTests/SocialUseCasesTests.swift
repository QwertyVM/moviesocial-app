import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Social Use Cases Tests")
struct SocialUseCasesTests {
    let socialRepo: SocialRepositoryProtocol
    let getActivityUseCase: GetFriendsActivityUseCase
    let submitReviewUseCase: SubmitReviewUseCase
    let addFriendUseCase: AddFriendUseCase
    let addCommentUseCase: AddCommentToReviewUseCase
    let toggleLikeUseCase: ToggleLikeReviewUseCase
    
    init() {
        let repo = SocialRepositoryImpl()
        self.socialRepo = repo
        self.getActivityUseCase = GetFriendsActivityUseCase(repository: repo)
        self.submitReviewUseCase = SubmitReviewUseCase(repository: repo)
        self.addFriendUseCase = AddFriendUseCase(repository: repo)
        self.addCommentUseCase = AddCommentToReviewUseCase(repository: repo)
        self.toggleLikeUseCase = ToggleLikeReviewUseCase(repository: repo)
    }
    
    @Test("Get Friends Feed Returns Activity")
    func getFriendsFeedReturnsActivity() async throws {
        let feed = try await getActivityUseCase.execute()
        #expect(!feed.isEmpty)
        #expect(feed.first?.movieTitle == "Duna: Parte dos")
    }
    
    @Test("Submit Review Adds New Review To Top")
    func submitReviewAddsNewReviewToTop() async throws {
        let testUser = User(
            id: "user_test",
            email: "test@apple.com",
            displayName: "Test Reviewer",
            authProvider: .apple
        )
        
        let newReview = try await submitReviewUseCase.execute(
            movieId: "129",
            movieTitle: "El Viaje de Chihiro",
            moviePosterURL: nil,
            movieReleaseYear: 2001,
            rating: 5.0,
            comment: "Una obra de arte absoluta.",
            user: testUser
        )
        
        #expect(newReview.movieTitle == "El Viaje de Chihiro")
        #expect(newReview.rating == 5.0)
        #expect(newReview.userName == "Test Reviewer")
        
        // Feed must contain it now
        let feed = try await getActivityUseCase.execute()
        #expect(feed.first?.id == newReview.id)
    }
    
    @Test("Add Friend")
    func addFriend() async throws {
        let newFriend = try await addFriendUseCase.execute(username: "@directora_cine")
        #expect(newFriend.username == "@directora_cine")
        
        let friends = try await socialRepo.getFriends()
        #expect(friends.contains(where: { $0.id == newFriend.id }))
    }
    
    @Test("Add Comment To Friend Review")
    func addCommentToFriendReview() async throws {
        let testUser = User(
            id: "user_cinefilo",
            email: "cine@movie.com",
            displayName: "Cinéfilo Experto",
            authProvider: .apple
        )
        
        let comment = try await addCommentUseCase.execute(
            reviewId: "rev_1",
            text: "¡La banda sonora de Hans Zimmer es impresionante!",
            user: testUser
        )
        
        #expect(comment.reviewId == "rev_1")
        #expect(comment.userName == "Cinéfilo Experto")
        #expect(comment.text == "¡La banda sonora de Hans Zimmer es impresionante!")
        
        let feed = try await getActivityUseCase.execute()
        let updatedReview = feed.first(where: { $0.id == "rev_1" })
        #expect(updatedReview?.comments.contains(where: { $0.id == comment.id }) == true)
    }
    
    @Test("Toggle Like On Friend Review")
    func toggleLikeOnFriendReview() async throws {
        let initialFeed = try await getActivityUseCase.execute()
        let review = try #require(initialFeed.first(where: { $0.id == "rev_1" }))
        let initialLikes = review.likesCount
        
        let toggleResult = try await toggleLikeUseCase.execute(reviewId: "rev_1", userId: "user_test")
        #expect(toggleResult.newCount != initialLikes)
    }
    
    @Test("Remove Friend")
    func removeFriend() async throws {
        let removeUseCase = RemoveFriendUseCase(repository: socialRepo)
        let initialFriends = try await socialRepo.getFriends()
        let friendToRemove = try #require(initialFriends.first)
        
        try await removeUseCase.execute(friendId: friendToRemove.id)
        
        let updatedFriends = try await socialRepo.getFriends()
        #expect(!updatedFriends.contains(where: { $0.id == friendToRemove.id }))
    }
    
    @Test("A user can only publish one review per movie (cannot duplicate)")
    func testUserCanOnlyPublishOneReview() async throws {
        let testUser = User(
            id: "user_unique_reviewer",
            email: "reviewer@cine.com",
            displayName: "Cinefilo 1",
            authProvider: .apple
        )
        
        // Primera publicación exitosa
        _ = try await submitReviewUseCase.execute(
            movieId: "550",
            movieTitle: "El Club de la Lucha",
            moviePosterURL: nil,
            movieReleaseYear: 1999,
            rating: 4.5,
            comment: "Excelente película",
            user: testUser
        )
        
        // Intentar publicar una segunda reseña para la misma película debe fallar
        await #expect(throws: SocialError.reviewAlreadyExists) {
            try await submitReviewUseCase.execute(
                movieId: "550",
                movieTitle: "El Club de la Lucha",
                moviePosterURL: nil,
                movieReleaseYear: 1999,
                rating: 5.0,
                comment: "Segunda reseña duplicada",
                user: testUser
            )
        }
    }
    
    @Test("Editing a review within 3 months updates in-place without creating history")
    func testEditingReviewWithinThreeMonths() async throws {
        let editReviewUseCase = EditReviewUseCase(repository: socialRepo)
        let testUser = User(
            id: "user_fast_editor",
            email: "editor@cine.com",
            displayName: "Editor Rápido",
            authProvider: .apple
        )
        
        let initialReview = try await submitReviewUseCase.execute(
            movieId: "680",
            movieTitle: "Pulp Fiction",
            moviePosterURL: nil,
            movieReleaseYear: 1994,
            rating: 4.0,
            comment: "Muy buena banda sonora y diálogos.",
            user: testUser
        )
        
        // Edición a los 15 días (menos de 3 meses)
        let editDate = initialReview.createdAt.addingTimeInterval(15 * 86400)
        let updatedReview = try await editReviewUseCase.execute(
            reviewId: initialReview.id,
            rating: 4.5,
            comment: "Obra maestra tras revisitarla.",
            currentDate: editDate
        )
        
        #expect(updatedReview.rating == 4.5)
        #expect(updatedReview.comment == "Obra maestra tras revisitarla.")
        #expect(updatedReview.isEdited == true)
        #expect(updatedReview.history.isEmpty)
        #expect(updatedReview.hasHistoricalRecord == false)
    }
    
    @Test("Editing a review after more than 3 months preserves the first review in history")
    func testEditingReviewAfterThreeMonthsPreservesFirstReview() async throws {
        let editReviewUseCase = EditReviewUseCase(repository: socialRepo)
        let testUser = User(
            id: "user_longterm_reviewer",
            email: "longterm@cine.com",
            displayName: "Cinéfilo Veterano",
            authProvider: .apple
        )
        
        let initialReview = try await submitReviewUseCase.execute(
            movieId: "155",
            movieTitle: "Batman: El Caballero de la Noche",
            moviePosterURL: nil,
            movieReleaseYear: 2008,
            rating: 4.0,
            comment: "Heath Ledger está magnífico.",
            user: testUser
        )
        
        // Simular que han pasado 4 meses (120 días)
        let editDate = initialReview.createdAt.addingTimeInterval(120 * 86400)
        let updatedReview = try await editReviewUseCase.execute(
            reviewId: initialReview.id,
            rating: 5.0,
            comment: "Con el tiempo envejece aún mejor. La mejor de superhéroes.",
            currentDate: editDate
        )
        
        // La reseña actual tiene la nueva puntuación y comentario
        #expect(updatedReview.rating == 5.0)
        #expect(updatedReview.comment == "Con el tiempo envejece aún mejor. La mejor de superhéroes.")
        #expect(updatedReview.isEdited == true)
        #expect(updatedReview.hasHistoricalRecord == true)
        #expect(updatedReview.history.count == 1)
        
        // La primera reseña queda preservada en el histórico
        let firstHistory = try #require(updatedReview.firstReviewHistory)
        #expect(firstHistory.rating == 4.0)
        #expect(firstHistory.comment == "Heath Ledger está magnífico.")
        #expect(firstHistory.createdAt == initialReview.createdAt)
        
        // Consultar historial por método del repositorio
        let history = try await socialRepo.getReviewHistory(reviewId: initialReview.id)
        #expect(history.count == 1)
        #expect(history.first?.rating == 4.0)
        
        // Verificar que el feed principal y listados de película no duplican la reseña
        let movieReviews = try await socialRepo.getReviewsForMovie(movieId: "155")
        let userReviewsForMovie = movieReviews.filter { $0.userId == testUser.id }
        #expect(userReviewsForMovie.count == 1)
        #expect(userReviewsForMovie.first?.rating == 5.0)
    }
    
    @Test("Subsequent edit after 3 months preserves original first review")
    func testSubsequentEditPreservesOriginalFirstReview() async throws {
        let editReviewUseCase = EditReviewUseCase(repository: socialRepo)
        let testUser = User(
            id: "user_multi_edit",
            email: "multi@cine.com",
            displayName: "Multi Editor",
            authProvider: .apple
        )
        
        let initialReview = try await submitReviewUseCase.execute(
            movieId: "11",
            movieTitle: "Star Wars: Una Nueva Esperanza",
            moviePosterURL: nil,
            movieReleaseYear: 1977,
            rating: 3.5,
            comment: "Buena para su época.",
            user: testUser
        )
        
        // Primera edición a los 4 meses (> 3 meses)
        let firstEditDate = initialReview.createdAt.addingTimeInterval(120 * 86400)
        _ = try await editReviewUseCase.execute(
            reviewId: initialReview.id,
            rating: 4.5,
            comment: "La disfruté muchísimo en 4K.",
            currentDate: firstEditDate
        )
        
        // Segunda edición a los 6 meses (> 3 meses)
        let secondEditDate = initialReview.createdAt.addingTimeInterval(180 * 86400)
        let finalReview = try await editReviewUseCase.execute(
            reviewId: initialReview.id,
            rating: 5.0,
            comment: "Un hito definitivo en la historia del cine.",
            currentDate: secondEditDate
        )
        
        #expect(finalReview.rating == 5.0)
        #expect(finalReview.firstReviewHistory?.rating == 3.5)
        #expect(finalReview.firstReviewHistory?.comment == "Buena para su época.")
        #expect(finalReview.history.count == 2)
    }
    
    @Test("MovieDetailViewModel routes submitReview to editReview when review already exists")
    func testMovieDetailViewModelRoutesSubmitToEdit() async throws {
        let repo = SocialRepositoryImpl()
        let movie = Movie(id: "19995", title: "Avatar", overview: "Pandora", releaseYear: 2009, posterURL: nil, genres: ["Sci-Fi"], runtimeMinutes: 162)
        let testUser = User(id: "user_vm_test", email: "vm@cine.com", displayName: "VM Reviewer", authProvider: .apple)
        
        let vm = MovieDetailViewModel(
            movie: movie,
            getMovieDetailUseCase: GetMovieDetailUseCase(repository: MovieRepositoryImpl()),
            getFriendsReviewsUseCase: GetFriendsReviewsForMovieUseCase(repository: repo),
            submitReviewUseCase: SubmitReviewUseCase(repository: repo),
            editReviewUseCase: EditReviewUseCase(repository: repo)
        )
        
        // Primera reseña enviada mediante el ViewModel
        let firstSuccess = await vm.submitReview(rating: 4.0, comment: "Gran impacto visual.", currentUser: testUser)
        #expect(firstSuccess == true)
        #expect(vm.friendReviews.count == 1)
        #expect(vm.friendReviews.first?.rating == 4.0)
        
        // Segundo envío para la misma película por el mismo usuario
        // Debe editar la existente y NO crear un segundo registro duplicado
        let secondSuccess = await vm.submitReview(rating: 4.5, comment: "El 3D sigue siendo insuperable.", currentUser: testUser)
        #expect(secondSuccess == true)
        
        let userReviews = vm.friendReviews.filter { $0.userId == testUser.id }
        #expect(userReviews.count == 1)
        #expect(userReviews.first?.rating == 4.5)
        #expect(userReviews.first?.comment == "El 3D sigue siendo insuperable.")
    }
    
    @Test("Friends list places online/connected friends first")
    func testFriendsListSortsOnlineFriendsFirst() async throws {
        let repo = SocialRepositoryImpl()
        let vm = SocialViewModel(
            getFriendsActivityUseCase: GetFriendsActivityUseCase(repository: repo),
            getFriendsListUseCase: GetFriendsListUseCase(repository: repo),
            addFriendUseCase: AddFriendUseCase(repository: repo)
        )
        
        await vm.loadSocialFeed()
        
        #expect(!vm.filteredFriends.isEmpty)
        
        // El primer elemento debe estar conectado si existen amigos en línea
        let onlineCount = vm.onlineFriendsCount
        #expect(onlineCount > 0)
        
        // Verificar que los primeros 'onlineCount' amigos están en línea
        for i in 0..<onlineCount {
            #expect(vm.filteredFriends[i].isOnline == true)
        }
        
        // Verificar que los subsecuentes están desconectados
        for i in onlineCount..<vm.filteredFriends.count {
            #expect(vm.filteredFriends[i].isOnline == false)
        }
    }
}
