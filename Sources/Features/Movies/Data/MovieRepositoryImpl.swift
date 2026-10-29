import Foundation

/// Implementación del repositorio de películas utilizando Swift 6 Actor para concurrencia segura
public actor MovieRepositoryImpl: MovieRepositoryProtocol {
    private let tmdbApiKey: String?
    private let omdbApiKey: String?
    private let urlSession: URLSession
    private let showtimesService: ShowtimesServiceProtocol
    
    // In-memory cache for movie details
    private var cache: [String: Movie] = [:]
    
    public init(
        tmdbApiKey: String? = nil,
        omdbApiKey: String? = nil,
        urlSession: URLSession = .shared,
        showtimesService: ShowtimesServiceProtocol = ShowtimesServiceImpl()
    ) {
        self.tmdbApiKey = tmdbApiKey
        self.omdbApiKey = omdbApiKey
        self.urlSession = urlSession
        self.showtimesService = showtimesService
        
        // Seed curated catalog
        for movie in Self.curatedMovies {
            cache[movie.id] = movie
        }
    }
    
    nonisolated public func getAvailableCities() -> [UserLocation] {
        showtimesService.getAvailableCities()
    }
    
    public func getNowPlaying(
        city: String? = nil,
        countryCode: String? = nil,
        page: Int = 1
    ) async throws -> [Movie] {
        var baseMovies: [Movie] = []
        if let tmdbApiKey, !tmdbApiKey.isEmpty {
            do {
                baseMovies = try await fetchTMDBNowPlaying(apiKey: tmdbApiKey, page: page, countryCode: countryCode)
            } catch {
                // Fallback to curated catalog
                baseMovies = Self.curatedMovies.filter { $0.releaseYear >= 2024 }
            }
        } else {
            baseMovies = Self.curatedMovies.filter { $0.releaseYear >= 2024 }
        }
        
        // Si no se especifica ciudad, devolver base
        guard let city, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return baseMovies
        }
        
        // Enriquecer con cartelera local de la ciudad
        let localTheatersMap = (try? await showtimesService.getMoviesInTheaters(
            city: city,
            countryCode: countryCode ?? ""
        )) ?? [:]
        
        let enriched = baseMovies.map { movie -> Movie in
            if let showtimes = localTheatersMap[movie.id], !showtimes.isEmpty {
                var copy = movie
                copy.isInTheatersLocally = true
                copy.theatersPlaying = Array(Set(showtimes.map(\.cinemaName))).sorted()
                copy.localShowtimes = showtimes
                return copy
            } else {
                return movie
            }
        }
        
        // Ordenar: primero las que están activas localmente en cines
        return enriched.sorted { (m1, m2) -> Bool in
            if m1.isInTheatersLocally != m2.isInTheatersLocally {
                return m1.isInTheatersLocally && !m2.isInTheatersLocally
            }
            return (m1.ratings.compositeScore ?? 0.0) > (m2.ratings.compositeScore ?? 0.0)
        }
    }
    
    public func getClassics(
        decade: Int? = nil,
        sortByRating: Bool = true,
        page: Int = 1
    ) async throws -> [Movie] {
        var baseClassics: [Movie] = []
        if let tmdbApiKey, !tmdbApiKey.isEmpty {
            do {
                baseClassics = try await fetchTMDBClassics(apiKey: tmdbApiKey, page: page)
            } catch {
                baseClassics = Self.curatedMovies.filter { $0.releaseYear < 2024 }
            }
        } else {
            baseClassics = Self.curatedMovies.filter { $0.releaseYear < 2024 }
        }
        
        // Filtrar por década si se solicita
        var filtered = baseClassics
        if let decade {
            if decade <= 1960 {
                filtered = filtered.filter { $0.releaseYear <= 1969 }
            } else {
                filtered = filtered.filter { $0.releaseYear >= decade && $0.releaseYear < decade + 10 }
            }
        }
        
        // Ordenar por el cruce de calificaciones (compositeScore) si está activo
        if sortByRating {
            filtered.sort { (m1, m2) -> Bool in
                let s1 = m1.ratings.compositeScore ?? (m1.ratings.imdbScore ?? 0.0)
                let s2 = m2.ratings.compositeScore ?? (m2.ratings.imdbScore ?? 0.0)
                return s1 > s2
            }
        }
        
        return filtered
    }
    
    public func searchMovies(query: String) async throws -> [Movie] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        
        if let tmdbApiKey, !tmdbApiKey.isEmpty {
            do {
                return try await fetchTMDBSearch(apiKey: tmdbApiKey, query: trimmed)
            } catch {
                // Fallback to searching curated
            }
        }
        
        return Self.curatedMovies.filter {
            $0.title.lowercased().contains(trimmed) ||
            $0.genres.contains { $0.lowercased().contains(trimmed) } ||
            String($0.releaseYear).contains(trimmed)
        }
    }
    
    public func getMovieDetail(id: String) async throws -> Movie {
        if let cached = cache[id] {
            return cached
        }
        
        if let tmdbApiKey, !tmdbApiKey.isEmpty, let intId = Int(id) {
            let movie = try await fetchTMDBDetail(apiKey: tmdbApiKey, id: intId)
            cache[id] = movie
            return movie
        }
        
        if let found = Self.curatedMovies.first(where: { $0.id == id }) {
            return found
        }
        
        throw NSError(domain: "MovieRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Película no encontrada"])
    }
    
    public func getAllMovies() async throws -> [Movie] {
        return Self.curatedMovies
    }
    
    // MARK: - Private Remote API Integration
    
    private func fetchTMDBNowPlaying(apiKey: String, page: Int, countryCode: String? = nil) async throws -> [Movie] {
        var urlString = "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)&page=\(page)&language=es-ES"
        if let countryCode, !countryCode.isEmpty {
            urlString += "&region=\(countryCode.uppercased())"
        }
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(TMDBResponseDTO.self, from: data)
        return response.results.map { dto in
            Movie(
                id: String(dto.id),
                title: dto.title,
                overview: dto.overview,
                releaseYear: extractYear(from: dto.releaseDate),
                releaseDate: dto.releaseDate,
                posterURL: dto.posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") },
                backdropURL: dto.backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") }
            )
        }
    }
    
    private func fetchTMDBClassics(apiKey: String, page: Int) async throws -> [Movie] {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/top_rated?api_key=\(apiKey)&page=\(page)&language=es-ES") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(TMDBResponseDTO.self, from: data)
        return response.results.map { dto in
            Movie(
                id: String(dto.id),
                title: dto.title,
                overview: dto.overview,
                releaseYear: extractYear(from: dto.releaseDate),
                releaseDate: dto.releaseDate,
                posterURL: dto.posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
            )
        }
    }
    
    private func fetchTMDBSearch(apiKey: String, query: String) async throws -> [Movie] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(apiKey)&query=\(encoded)&language=es-ES") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(TMDBResponseDTO.self, from: data)
        return response.results.map { dto in
            Movie(
                id: String(dto.id),
                title: dto.title,
                overview: dto.overview,
                releaseYear: extractYear(from: dto.releaseDate),
                releaseDate: dto.releaseDate,
                posterURL: dto.posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
            )
        }
    }
    
    private func fetchTMDBDetail(apiKey: String, id: Int) async throws -> Movie {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(id)?api_key=\(apiKey)&append_to_response=external_ids&language=es-ES") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await urlSession.data(from: url)
        let detail = try JSONDecoder().decode(TMDBMovieDetailDTO.self, from: data)
        
        var ratings = ExternalRatings()
        if let imdbId = detail.imdbId, let omdbApiKey, !omdbApiKey.isEmpty {
            ratings = (try? await fetchOMDbRatings(imdbId: imdbId, apiKey: omdbApiKey)) ?? ExternalRatings()
        }
        
        return Movie(
            id: String(detail.id),
            title: detail.title,
            overview: detail.overview,
            releaseYear: extractYear(from: detail.releaseDate),
            releaseDate: detail.releaseDate,
            posterURL: detail.posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") },
            backdropURL: detail.backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") },
            genres: detail.genres?.map(\.name) ?? [],
            runtimeMinutes: detail.runtime,
            imdbId: detail.imdbId,
            ratings: ratings
        )
    }
    
    private func fetchOMDbRatings(imdbId: String, apiKey: String) async throws -> ExternalRatings {
        guard let url = URL(string: "https://www.omdbapi.com/?i=\(imdbId)&apikey=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await urlSession.data(from: url)
        let dto = try JSONDecoder().decode(OMDbMovieDTO.self, from: data)
        return dto.toExternalRatings()
    }
    
    private func extractYear(from dateString: String?) -> Int {
        guard let dateString, dateString.count >= 4,
              let year = Int(dateString.prefix(4)) else {
            return 2024
        }
        return year
    }
    
    // MARK: - Curated Real-World Catalog with Authentic Rotten Tomatoes & IMDb Scores
    public static let curatedMovies: [Movie] = [
        // ESTRENOS RECIENTES
        Movie(
            id: "693134",
            title: "Dune: Parte Dos",
            overview: "Paul Atreides se une a Chani y a los Fremen mientras busca venganza contra los conspiradores que destruyeron a su familia, enfrentándose a una elección entre el amor de su vida y el destino del universo.",
            releaseYear: 2024,
            releaseDate: "2024-03-01",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/xOMo8BRK7PfcJv9JCnx7s5200bm.jpg"),
            genres: ["Ciencia Ficción", "Aventura"],
            runtimeMinutes: 166,
            imdbId: "tt15239678",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 92,
                rottenTomatoesAudience: 95,
                imdbScore: 8.5,
                imdbVotes: "480K"
            )
        ),
        Movie(
            id: "1022789",
            title: "Del Revés 2 (Inside Out 2)",
            overview: "Riley entra en la adolescencia y el Cuartel General sufre una repentina reforma para hacer espacio a algo totalmente inesperado: ¡nuevas emociones! Alegría, Tristeza, Furia, Temor y Desagrado reciben a Ansiedad, Envidia, Ennui y Vergüenza.",
            releaseYear: 2024,
            releaseDate: "2024-06-14",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg"),
            genres: ["Animación", "Familia", "Comedia"],
            runtimeMinutes: 96,
            imdbId: "tt22022452",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 91,
                rottenTomatoesAudience: 96,
                imdbScore: 7.7,
                imdbVotes: "210K"
            )
        ),
        Movie(
            id: "533535",
            title: "Deadpool & Wolverine",
            overview: "Un apático Wade Wilson se afana en la vida civil tras dejar atrás sus días como Deadpool. Pero cuando su mundo natal se enfrenta a una amenaza existencial, Wade debe volver a ponerse el traje junto a un reacio Wolverine.",
            releaseYear: 2024,
            releaseDate: "2024-07-26",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg"),
            genres: ["Acción", "Comedia", "Ciencia Ficción"],
            runtimeMinutes: 128,
            imdbId: "tt6263850",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 78,
                rottenTomatoesAudience: 94,
                imdbScore: 7.8,
                imdbVotes: "380K"
            )
        ),
        Movie(
            id: "872585",
            title: "Oppenheimer",
            overview: "La historia del físico estadounidense J. Robert Oppenheimer, su papel al frente del Proyecto Manhattan y el desarrollo de la bomba atómica durante la Segunda Guerra Mundial.",
            releaseYear: 2024,
            releaseDate: "2023-07-21",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg"),
            genres: ["Drama", "Historia"],
            runtimeMinutes: 180,
            imdbId: "tt15398776",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 93,
                rottenTomatoesAudience: 91,
                imdbScore: 8.9,
                imdbVotes: "750K"
            )
        ),
        
        // CLÁSICOS INMORTALES
        Movie(
            id: "238",
            title: "El Padrino (The Godfather)",
            overview: "El patriarca de una dinastía del crimen organizado traslada el control de su imperio clandestino a su reacio hijo menor.",
            releaseYear: 1972,
            releaseDate: "1972-03-24",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            genres: ["Crimen", "Drama"],
            runtimeMinutes: 175,
            imdbId: "tt0068646",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 97,
                rottenTomatoesAudience: 98,
                imdbScore: 9.2,
                imdbVotes: "2.0M"
            )
        ),
        Movie(
            id: "680",
            title: "Pulp Fiction",
            overview: "Las vidas de dos mafiosos, la esposa de un gánster, un boxeador y dos asaltantes de poca monta se entrelazan en cuatro historias de violencia y redención.",
            releaseYear: 1994,
            releaseDate: "1994-10-14",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg"),
            genres: ["Crimen", "Suspense"],
            runtimeMinutes: 154,
            imdbId: "tt0110912",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 92,
                rottenTomatoesAudience: 96,
                imdbScore: 8.9,
                imdbVotes: "2.2M"
            )
        ),
        Movie(
            id: "389",
            title: "12 Hombres en Pugna (12 Angry Men)",
            overview: "El juicio por asesinato de un joven de 18 años parece claro hasta que uno de los doce miembros del jurado vota inocente y obliga a los demás a reconsiderar las pruebas.",
            releaseYear: 1957,
            releaseDate: "1957-04-10",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/ppd84D2i9W8jXmsyGtG0FTz9umD.jpg"),
            genres: ["Drama"],
            runtimeMinutes: 96,
            imdbId: "tt0050083",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 100,
                rottenTomatoesAudience: 97,
                imdbScore: 9.0,
                imdbVotes: "870K"
            )
        ),
        Movie(
            id: "129",
            title: "El Viaje de Chihiro (Spirited Away)",
            overview: "Chihiro, una niña de 10 años, queda atrapada en un mundo mágico gobernado por una bruja tras la misteriosa transformación de sus padres en cerdos.",
            releaseYear: 2001,
            releaseDate: "2001-07-20",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/393r8pU4i7L57jO7i3b6jA0N3s.jpg"),
            genres: ["Animación", "Fantasía", "Aventura"],
            runtimeMinutes: 125,
            imdbId: "tt0245429",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 97,
                rottenTomatoesAudience: 96,
                imdbScore: 8.6,
                imdbVotes: "850K"
            )
        ),
        Movie(
            id: "157336",
            title: "Interstellar",
            overview: "Un equipo de exploradores viaja a través de un agujero de gusano en el espacio en un intento por asegurar la supervivencia de la humanidad ante una Tierra moribunda.",
            releaseYear: 2014,
            releaseDate: "2014-11-07",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/xJHokMbljvjADYdit5fK5VQsXEG.jpg"),
            genres: ["Ciencia Ficción", "Drama", "Aventura"],
            runtimeMinutes: 169,
            imdbId: "tt0816692",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 73,
                rottenTomatoesAudience: 86,
                imdbScore: 8.7,
                imdbVotes: "2.1M"
            )
        ),
        Movie(
            id: "569094",
            title: "Spider-Man: Cruzando el Multiverso",
            overview: "Miles Morales es catapultado a través del Multiverso, donde se encuentra con una Sociedad Araña encargada de proteger su existencia frente a una nueva amenaza.",
            releaseYear: 2023,
            releaseDate: "2023-06-02",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/4HodYYKEIsGOdinkGi2Ucz6X9i0.jpg"),
            genres: ["Animación", "Acción", "Aventura", "Ciencia Ficción"],
            runtimeMinutes: 140,
            imdbId: "tt9362722",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 95,
                rottenTomatoesAudience: 94,
                imdbScore: 8.6,
                imdbVotes: "400K"
            )
        ),
        Movie(
            id: "496243",
            title: "Parásitos (Parasite)",
            overview: "Tanto Gi Taek como su familia están sin trabajo. Cuando su hijo mayor empieza a dar clases particulares en la adinerada casa de los Park, las dos familias comienzan una interrelación de resultados imprevisibles.",
            releaseYear: 2019,
            releaseDate: "2019-05-30",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/hiKmpFcDHioyz4SVNvODmU2uvT2.jpg"),
            genres: ["Suspense", "Drama", "Comedia"],
            runtimeMinutes: 132,
            imdbId: "tt6751668",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 99,
                rottenTomatoesAudience: 95,
                imdbScore: 8.5,
                imdbVotes: "950K"
            )
        ),
        Movie(
            id: "155",
            title: "El Caballero Oscuro (The Dark Knight)",
            overview: "Batman se propone desmantelar las organizaciones criminales restantes que plagan las calles de Gotham, pero pronto se encuentra presa del reinado del caos desatado por el Joker.",
            releaseYear: 2008,
            releaseDate: "2008-07-18",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg"),
            genres: ["Acción", "Crimen", "Drama"],
            runtimeMinutes: 152,
            imdbId: "tt0468569",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 94,
                rottenTomatoesAudience: 94,
                imdbScore: 9.0,
                imdbVotes: "2.9M"
            )
        ),
        Movie(
            id: "313369",
            title: "La La Land (La Ciudad de las Estrellas)",
            overview: "Una aspirante a actriz y un dedicado pianista de jazz luchan por llegar a fin de mes mientras persiguen sus sueños en Los Ángeles, enfrentándose a decisiones que pondrán a prueba su amor.",
            releaseYear: 2016,
            releaseDate: "2016-12-09",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/uDO8zWDhfWwoFdKS4fzkVJt0Rf0.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/nadTmkT5EuNu2dmYsGrdLDFppLs.jpg"),
            genres: ["Comedia", "Drama", "Romance", "Música"],
            runtimeMinutes: 128,
            imdbId: "tt3783958",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 91,
                rottenTomatoesAudience: 81,
                imdbScore: 8.0,
                imdbVotes: "670K"
            )
        ),
        Movie(
            id: "945961",
            title: "Alien: Romulus",
            overview: "Mientras hurgan en las profundidades de una estación espacial abandonada, un grupo de jóvenes colonizadores se encuentra cara a cara con la forma de vida más aterradora del universo.",
            releaseYear: 2024,
            releaseDate: "2024-08-16",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/9SSEUrSqhljBMzRe4aBTh17rUaC.jpg"),
            genres: ["Terror", "Ciencia Ficción", "Suspense"],
            runtimeMinutes: 119,
            imdbId: "tt18412256",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 80,
                rottenTomatoesAudience: 85,
                imdbScore: 7.2,
                imdbVotes: "190K"
            )
        ),
        
        // MÁS CLÁSICOS POR DÉCADAS
        Movie(
            id: "289",
            title: "Casablanca",
            overview: "Durante la Segunda Guerra Mundial, el hastiado propietario de un club nocturno en Casablanca se debate entre el amor y la virtud moral al ayudar a su antiguo amor y a su esposo refugiado.",
            releaseYear: 1942,
            releaseDate: "1942-11-26",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/5K7cOHoay2mZusSLezBOY0Qxh8a.jpg"),
            genres: ["Drama", "Romance", "Guerra"],
            runtimeMinutes: 102,
            imdbId: "tt0034583",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 99,
                rottenTomatoesAudience: 95,
                imdbScore: 8.5,
                imdbVotes: "610K"
            )
        ),
        Movie(
            id: "278",
            title: "Cadena Perpetua (The Shawshank Redemption)",
            overview: "Condenado a cadena perpetua por el asesinato de su esposa y su amante, un banquero inocente entabla amistad con otro recluso y encuentra esperanza a través de actos de decencia común.",
            releaseYear: 1994,
            releaseDate: "1994-09-23",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg"),
            genres: ["Drama", "Crimen"],
            runtimeMinutes: 142,
            imdbId: "tt0111161",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 91,
                rottenTomatoesAudience: 98,
                imdbScore: 9.3,
                imdbVotes: "2.9M"
            )
        ),
        Movie(
            id: "424",
            title: "La Lista de Schindler",
            overview: "En la Polonia ocupada por los alemanes durante la Segunda Guerra Mundial, Oskar Schindler gradualmente se preocupa por su fuerza laboral judía después de presenciar su persecución por los nazis.",
            releaseYear: 1993,
            releaseDate: "1993-12-15",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/sF1U4EUQS8YHUYjNlvt0xTWQ1Ac.jpg"),
            genres: ["Drama", "Historia", "Guerra"],
            runtimeMinutes: 195,
            imdbId: "tt0108052",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 98,
                rottenTomatoesAudience: 97,
                imdbScore: 9.0,
                imdbVotes: "1.4M"
            )
        ),
        Movie(
            id: "105",
            title: "Regreso al Futuro (Back to the Future)",
            overview: "Marty McFly, un estudiante de secundaria típico de los años 80, es enviado accidentalmente a 1955 en un automóvil DeLorean modificado para viajar en el tiempo por un excéntrico científico.",
            releaseYear: 1985,
            releaseDate: "1985-07-03",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/fNOH9f1aA7XRTzl1sAOx9iF553Q.jpg"),
            genres: ["Aventura", "Comedia", "Ciencia Ficción"],
            runtimeMinutes: 116,
            imdbId: "tt0088763",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 93,
                rottenTomatoesAudience: 94,
                imdbScore: 8.5,
                imdbVotes: "1.3M"
            )
        ),
        Movie(
            id: "244786",
            title: "Whiplash",
            overview: "Un joven y prometedor baterista de jazz se matricula en un conservatorio de música muy competitivo donde sus sueños de grandeza son guiados por un despiadado instructor.",
            releaseYear: 2014,
            releaseDate: "2014-10-10",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/7fn624j5lj3xTme2SgiLCeuedmO.jpg"),
            genres: ["Drama", "Música"],
            runtimeMinutes: 107,
            imdbId: "tt2582802",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 94,
                rottenTomatoesAudience: 94,
                imdbScore: 8.5,
                imdbVotes: "980K"
            )
        )
    ]
}
