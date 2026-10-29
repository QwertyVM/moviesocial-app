import Foundation

/// Caso de uso que genera recomendaciones personalizadas basadas en los puntajes que el usuario otorgó a otras películas
public struct GetRecommendedMoviesUseCase: Sendable {
    private let movieRepository: MovieRepositoryProtocol
    private let socialRepository: SocialRepositoryProtocol
    
    public init(
        movieRepository: MovieRepositoryProtocol,
        socialRepository: SocialRepositoryProtocol
    ) {
        self.movieRepository = movieRepository
        self.socialRepository = socialRepository
    }
    
    public struct RecommendationResult: Sendable {
        public let movies: [Movie]
        public let userRatedCount: Int
        public let topGenres: [String]
        
        public init(movies: [Movie], userRatedCount: Int, topGenres: [String]) {
            self.movies = movies
            self.userRatedCount = userRatedCount
            self.topGenres = topGenres
        }
    }
    
    public func execute(userId: String) async throws -> RecommendationResult {
        // 1. Obtener todas las valoraciones y reseñas del usuario
        let userReviews = try await socialRepository.getUserReviews(userId: userId)
        
        // 2. Obtener todas las películas del catálogo
        let allMovies = try await movieRepository.getAllMovies()
        
        // Si el usuario no tiene ninguna película calificada (Cold-Start)
        guard !userReviews.isEmpty else {
            return RecommendationResult(movies: [], userRatedCount: 0, topGenres: [])
        }
        
        // 3. Identificar IDs de películas ya calificadas para no recomendarlas de nuevo
        let ratedMovieIds = Set(userReviews.map(\.movieId))
        
        // 4. Calcular vector de afinidad por género basado en los puntajes asignados (escala 1.0 a 5.0)
        var genreWeights: [String: Double] = [:]
        
        for review in userReviews {
            // Ponderación según la puntuación asignada:
            // 5.0 -> +3.0 (Gran afinidad)
            // 4.5 -> +2.0
            // 4.0 -> +1.0
            // 3.5 -> +0.4
            // 3.0 -> 0.0 (Neutro)
            // < 3.0 -> -2.0 (Penalización de género)
            let weight: Double
            if review.rating >= 4.8 {
                weight = 3.0
            } else if review.rating >= 4.3 {
                weight = 2.0
            } else if review.rating >= 3.8 {
                weight = 1.0
            } else if review.rating >= 3.3 {
                weight = 0.4
            } else if review.rating >= 2.8 {
                weight = 0.0
            } else {
                weight = -2.0
            }
            
            // Localizar la película en el catálogo para conocer sus géneros
            if let ratedMovie = allMovies.first(where: { $0.id == review.movieId }) {
                for genre in ratedMovie.genres {
                    genreWeights[genre, default: 0.0] += weight
                }
            }
        }
        
        // Géneros favoritos ordenados por peso acumulado
        let topGenres = genreWeights
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map(\.key)
        
        // Películas que el usuario calificó muy alto (>= 4.0), ordenadas descendentemente
        let favoriteReviews = userReviews
            .filter { $0.rating >= 4.0 }
            .sorted { $0.rating > $1.rating }
        
        // 5. Filtrar candidatos: películas que el usuario aún NO ha calificado
        let candidateMovies = allMovies.filter { !ratedMovieIds.contains($0.id) }
        
        // 6. Evaluar compatibilidad de cada candidata
        var scoredList: [(movie: Movie, score: Double, reason: String)] = []
        
        for candidate in candidateMovies {
            var score: Double = 0.0
            var matchedPositiveGenres: [String] = []
            
            for genre in candidate.genres {
                if let w = genreWeights[genre] {
                    score += w
                    if w > 0 {
                        matchedPositiveGenres.append(genre)
                    }
                }
            }
            
            // Añadir un leve factor de calidad crítica externa para ordenar empates
            if let imdb = candidate.ratings.imdbScore {
                score += (imdb - 7.0) * 0.25
            }
            if let rt = candidate.ratings.rottenTomatoesCritics {
                score += (Double(rt) - 75.0) * 0.015
            }
            
            // Construir motivo explicable de la recomendación
            var reason = "Recomendado para ti"
            
            // ¿Coincide con alguna de sus películas favoritas calificadas con 4★ o 5★?
            if let favoriteReview = favoriteReviews.first(where: { fav in
                if let favMovie = allMovies.first(where: { $0.id == fav.movieId }) {
                    return !Set(favMovie.genres).isDisjoint(with: candidate.genres)
                }
                return false
            }) {
                reason = "Porque te gustó \"\(favoriteReview.movieTitle)\""
            } else if !matchedPositiveGenres.isEmpty {
                reason = "Por tu afinidad con \(matchedPositiveGenres.prefix(2).joined(separator: " y "))"
            }
            
            scoredList.append((movie: candidate, score: score, reason: reason))
        }
        
        // Ordenar candidatas por compatibilidad
        scoredList.sort { $0.score > $1.score }
        
        // Normalizar los scores a porcentaje de compatibilidad (78% a 99%)
        let positiveCandidates = scoredList.filter { $0.score > 0 }
        guard let maxScore = positiveCandidates.first?.score, maxScore > 0 else {
            return RecommendationResult(
                movies: [],
                userRatedCount: userReviews.count,
                topGenres: Array(topGenres.prefix(3))
            )
        }
        
        var finalMovies: [Movie] = []
        for item in positiveCandidates {
            let normalizedRatio = item.score / max(maxScore, 1.0)
            let percentage = Int(78.0 + (normalizedRatio * 21.0))
            let clampedPercentage = min(99, max(75, percentage))
            
            var movie = item.movie
            movie.matchScore = clampedPercentage
            movie.recommendationReason = item.reason
            finalMovies.append(movie)
        }
        
        return RecommendationResult(
            movies: finalMovies,
            userRatedCount: userReviews.count,
            topGenres: Array(topGenres.prefix(3))
        )
    }
}
