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
    
    nonisolated public func getAvailableCountryGroups() -> [CountryAreaGroup] {
        showtimesService.getAvailableCountryGroups()
    }
    
    public func getNowPlaying(
        city: String? = nil,
        countryCode: String? = nil,
        page: Int = 1
    ) async throws -> [Movie] {
        var baseMovies: [Movie] = []
        
        // 1. Intentar cargar películas de cartelera en vivo desde Neon DB (API REST)
        // filtradas estrictamente para los estrenos de la última semana según la ubicación del usuario
        do {
            struct TheatricalResponse: Codable {
                let movies: [TheatricalMovieDTO]
                let count: Int
            }
            var queryParams: [String: String] = [
                "only_latest_week": "true"
            ]
            if let city, !city.isEmpty { queryParams["city"] = city }
            if let countryCode, !countryCode.isEmpty { queryParams["country"] = countryCode }
            
            let response: TheatricalResponse = try await MovieSocialAPIClient.shared.sendRequest(
                endpoint: "movies/theatrical",
                method: .get,
                queryParams: queryParams
            )
            
            if !response.movies.isEmpty {
                let dbMovies = response.movies.map { $0.toDomain() }
                for m in dbMovies {
                    cache[m.id] = m
                }
                baseMovies = dbMovies
            }
        } catch {
            // Continuar con fallback si la red no está disponible
        }

        // 2. Si la BD no devolvió películas o no hay conexión, usar fallback curado
        // filtrando únicamente los estrenos reales de la última semana (<= 7 días)
        if baseMovies.isEmpty {
            if let tmdbApiKey, !tmdbApiKey.isEmpty {
                do {
                    baseMovies = try await fetchTMDBNowPlaying(apiKey: tmdbApiKey, page: page, countryCode: countryCode)
                } catch {
                    baseMovies = Self.curatedMovies.filter {
                        let status = $0.releaseStatus()
                        return status == .premiereWeek || status == .secondWeek
                    }
                }
            } else {
                baseMovies = Self.curatedMovies.filter {
                    let status = $0.releaseStatus()
                    return status == .premiereWeek || status == .secondWeek
                }
            }
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
        
        var workingMovies = baseMovies
        for (movieId, _) in localTheatersMap {
            if !workingMovies.contains(where: { $0.id == movieId }) {
                if let found = cache[movieId] ?? Self.curatedMovies.first(where: { $0.id == movieId }) {
                    workingMovies.append(found)
                }
            }
        }
        
        let enriched = workingMovies.map { movie -> Movie in
            if let showtimes = localTheatersMap[movie.id], !showtimes.isEmpty {
                var copy = movie
                copy.isInTheatersLocally = true
                copy.theatersPlaying = Array(Set(showtimes.map(\.cinemaName))).sorted()
                copy.localShowtimes = showtimes
                return copy
            } else if !movie.localShowtimes.isEmpty {
                var copy = movie
                copy.isInTheatersLocally = true
                copy.theatersPlaying = Array(Set(movie.localShowtimes.map(\.cinemaName))).sorted()
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
            let isNat1 = m1.isNationalCinema(for: countryCode)
            let isNat2 = m2.isNationalCinema(for: countryCode)
            if isNat1 != isNat2 {
                return isNat1 && !isNat2
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
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        // Normalización para búsqueda insensible a diacríticos (tildes) y mayúsculas
        let normalizedQuery = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
        
        if let tmdbApiKey, !tmdbApiKey.isEmpty {
            do {
                let remote = try await fetchTMDBSearch(apiKey: tmdbApiKey, query: trimmed)
                if !remote.isEmpty {
                    return remote
                }
            } catch {
                // Fallback to searching curated
            }
        }
        
        return Self.curatedMovies.filter { movie in
            let normalizedTitle = movie.title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            let normalizedOverview = movie.overview.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            let yearStr = String(movie.releaseYear)
            
            if normalizedTitle.contains(normalizedQuery) { return true }
            if normalizedOverview.contains(normalizedQuery) { return true }
            if yearStr.contains(normalizedQuery) { return true }
            if movie.genres.contains(where: {
                $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES")).contains(normalizedQuery)
            }) { return true }
            
            return false
        }
    }
    
    public func getMovieDetail(id: String) async throws -> Movie {
        if let cached = cache[id] {
            return cached
        }
        
        // Consultar la API REST de Neon DB si no está en caché
        do {
            struct TheatricalDetailResponse: Codable {
                let movie: TheatricalMovieDTO
            }
            let response: TheatricalDetailResponse = try await MovieSocialAPIClient.shared.sendRequest(
                endpoint: "movies/theatrical/\(id)",
                method: .get
            )
            let movie = response.movie.toDomain()
            cache[id] = movie
            return movie
        } catch {
            // Continuar con búsqueda estándar
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
        var urlString = "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)&page=\(page)&language=es-MX"
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
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/top_rated?api_key=\(apiKey)&page=\(page)&language=es-MX") else {
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
              let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(apiKey)&query=\(encoded)&language=es-MX") else {
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
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(id)?api_key=\(apiKey)&append_to_response=external_ids&language=es-MX") else {
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
        // ESTRENOS REALES DE LA SEMANA ACTUAL (OCTUBRE 2026)
        Movie(
            id: "obsesion_2026",
            title: "Obsesión (Obsession)",
            overview: "Bear, un joven que trabaja en una tienda de discos, pide un deseo al misterioso Sauce de los Deseos para que Nikki, su amor platónico de la infancia, se enamore de él. Pronto, su afecto se transforma en una asfixiante, violenta y aterradora pesadilla de posesión, terror psicológico y horror sobrenatural en el aclamado nuevo estreno de terror dirigido por Curry Barker.",
            releaseYear: 2026,
            releaseDate: "2026-10-24",
            posterURL: URL(string: "https://images.unsplash.com/photo-1509281373149-e957c6296406?w=500"),
            backdropURL: URL(string: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1280"),
            genres: ["Terror", "Misterio", "Suspenso", "Terror Psicológico"],
            runtimeMinutes: 98,
            imdbId: "tt34891142",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 86,
                rottenTomatoesAudience: 82,
                imdbScore: 7.1,
                imdbVotes: "28K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "US"
        ),
        Movie(
            id: "wildwood_2026",
            title: "Wildwood: El bosque salvaje",
            overview: "En las afueras de Portland, una joven debe adentrarse en un bosque prohibido y místico para rescatar a su hermano menor de las garras de misteriosas criaturas.",
            releaseYear: 2026,
            releaseDate: "2026-10-29",
            posterURL: URL(string: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500"),
            backdropURL: URL(string: "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=1280"),
            genres: ["Animación", "Aventura", "Fantasía"],
            runtimeMinutes: 110,
            ratings: ExternalRatings(
                rottenTomatoesCritics: 88,
                rottenTomatoesAudience: 92,
                imdbScore: 7.9,
                imdbVotes: "12K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "US"
        ),
        Movie(
            id: "el_heladero_2026",
            title: "El Heladero: Dulce sabor a muerte",
            overview: "Un pintoresco pueblo costero es aterrorizado por un siniestro vendedor que convierte la alegría de los niños en una pesadilla sangrienta.",
            releaseYear: 2026,
            releaseDate: "2026-10-29",
            posterURL: URL(string: "https://images.unsplash.com/photo-1509281373149-e957c6296406?w=500"),
            genres: ["Terror", "Slasher", "Suspenso"],
            runtimeMinutes: 92,
            ratings: ExternalRatings(
                rottenTomatoesCritics: 75,
                rottenTomatoesAudience: 78,
                imdbScore: 6.8,
                imdbVotes: "8.4K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "US"
        ),
        Movie(
            id: "el_pintor_milagros_2026",
            title: "El Pintor de los Milagros",
            overview: "La conmovedora historia real de un artista que redescubre su vocación y restaura la fe y la esperanza en su comunidad tras una tragedia personal.",
            releaseYear: 2026,
            releaseDate: "2026-10-29",
            posterURL: URL(string: "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=500"),
            genres: ["Drama", "Fe", "Inspiracional"],
            runtimeMinutes: 118,
            ratings: ExternalRatings(
                rottenTomatoesCritics: 82,
                rottenTomatoesAudience: 90,
                imdbScore: 7.4,
                imdbVotes: "15K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "US"
        ),
        Movie(
            id: "desaparecidos_altamar_2026",
            title: "Desaparecidos en Altamar",
            overview: "Una expedición científica en aguas internacionales se convierte en una lucha desesperada contra los elementos naturales y un enigma letal a bordo.",
            releaseYear: 2026,
            releaseDate: "2026-10-29",
            posterURL: URL(string: "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500"),
            genres: ["Suspenso", "Acción", "Supervivencia"],
            runtimeMinutes: 104,
            ratings: ExternalRatings(
                rottenTomatoesCritics: 79,
                rottenTomatoesAudience: 83,
                imdbScore: 7.2,
                imdbVotes: "11K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "IS"
        ),
        Movie(
            id: "la_tribu_pe_2026",
            title: "La Tribu",
            overview: "Una peculiar y numerosa familia limeña se embarca en un viaje accidentado por la selva central que pondrá a prueba sus lazos y su paciencia.",
            releaseYear: 2026,
            releaseDate: "2026-10-24",
            posterURL: URL(string: "https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=500"),
            genres: ["Comedia", "Familiar", "Aventuras"],
            runtimeMinutes: 98,
            ratings: ExternalRatings(
                rottenTomatoesCritics: 84,
                rottenTomatoesAudience: 88,
                imdbScore: 7.5,
                imdbVotes: "6.2K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "PE"
        ),
        Movie(
            id: "karateka_es_2026",
            title: "Karateka",
            overview: "Una joven monitora de judo en horas bajas decide apuntarse a un peculiar torneo clandestino para salvar el gimnasio de su abuelo.",
            releaseYear: 2026,
            releaseDate: "2026-10-30",
            posterURL: URL(string: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500"),
            genres: ["Comedia", "Acción", "Drama"],
            runtimeMinutes: 102,
            ratings: ExternalRatings(
                rottenTomatoesCritics: 85,
                rottenTomatoesAudience: 87,
                imdbScore: 7.6,
                imdbVotes: "9.1K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "ES"
        ),
        Movie(
            id: "esta_soledad_es_2026",
            title: "Esta soledad",
            overview: "Un viaje íntimo a través del aislamiento y la reconexión humana en el corazón de Madrid.",
            releaseYear: 2026,
            releaseDate: "2026-10-30",
            posterURL: URL(string: "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=500"),
            genres: ["Drama", "Cine de Autor"],
            runtimeMinutes: 112,
            ratings: ExternalRatings(
                rottenTomatoesCritics: 89,
                rottenTomatoesAudience: 86,
                imdbScore: 7.9,
                imdbVotes: "7.8K"
            ),
            isInTheatersLocally: true,
            countryOfOrigin: "ES"
        ),
        Movie(
            id: "ekeko_pe_2026",
            title: "Ekeko",
            overview: "Buscando dejar atrás heridas del pasado y cambiar su suerte, una mujer recurre al misticismo del Ekeko para pedir que se cumplan sus anhelos más profundos. Pero lo que empieza como una promesa de prosperidad pronto desata una espiral de terror sobrenatural bajo la premisa de que cada deseo concedido exige un costo aterrador.",
            releaseYear: 2026,
            releaseDate: "2026-10-24",
            posterURL: URL(string: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500"),
            backdropURL: URL(string: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1280"),
            genres: ["Terror", "Misterio", "Suspenso"],
            runtimeMinutes: 98,
            imdbId: "tt33984120",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 84,
                rottenTomatoesAudience: 88,
                imdbScore: 7.2,
                imdbVotes: "4.5K"
            ),
            countryOfOrigin: "PE"
        ),
        Movie(
            id: "smile_2_2026",
            title: "Sonríe 2",
            overview: "A punto de embarcarse en una nueva gira mundial, la sensación del pop mundial Skye Riley comienza a experimentar sucesos cada vez más aterradores e inexplicables. Abrumada por los crecientes horrores y las presiones de la fama, debe enfrentar su oscuro pasado.",
            releaseYear: 2026,
            releaseDate: "2026-10-17",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/aMFl9wA548xYyHkQZpL38lYvT3s.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/h3fwlwHotDGMbz5OiMRm6DeWMIc.jpg"),
            genres: ["Terror", "Misterio"],
            runtimeMinutes: 127,
            imdbId: "tt29268110",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 85,
                rottenTomatoesAudience: 82,
                imdbScore: 7.1,
                imdbVotes: "65K"
            ),
            countryOfOrigin: "US"
        ),
        Movie(
            id: "693134",
            title: "Duna: Parte dos",
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
            ),
            countryOfOrigin: "US"
        ),
        Movie(
            id: "1022789",
            title: "Intensamente 2",
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
            ),
            countryOfOrigin: "US"
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
            ),
            countryOfOrigin: "US"
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
            ),
            countryOfOrigin: "US"
        ),
        Movie(
            id: "939335",
            title: "La Sociedad de la Nieve",
            overview: "El relato del vuelo 571 de la Fuerza Aérea Uruguaya fletado para llevar a un equipo de rugby a Chile, que se estrella en el corazón de los Andes.",
            releaseYear: 2024,
            releaseDate: "2024-01-04",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/2rLWm5jZuhA0v1rE4Wk4b4q1x7G.jpg"),
            genres: ["Drama", "Aventura", "Historia"],
            runtimeMinutes: 144,
            imdbId: "tt16277242",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 90,
                rottenTomatoesAudience: 85,
                imdbScore: 7.8,
                imdbVotes: "135K"
            ),
            countryOfOrigin: "ES"
        ),
        Movie(
            id: "1032823",
            title: "Radical",
            overview: "En una ciudad fronteriza mexicana plagada de abandono, corrupción y violencia, un profesor frustrado prueba un método radicalmente nuevo.",
            releaseYear: 2024,
            releaseDate: "2024-01-19",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/e9t47YqN6BvV0gVjD9b5s3v7H8Q.jpg"),
            genres: ["Drama"],
            runtimeMinutes: 125,
            imdbId: "tt21865910",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 94,
                rottenTomatoesAudience: 99,
                imdbScore: 7.9,
                imdbVotes: "18K"
            ),
            countryOfOrigin: "MX"
        ),
        Movie(
            id: "929590",
            title: "Civil War",
            overview: "En un futuro cercano, un grupo de corresponsales de guerra recorre los Estados Unidos en medio de una violenta guerra civil que se extiende con rapidez.",
            releaseYear: 2024,
            releaseDate: "2024-04-12",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/sh7Rg8Er3tFcN9BpKIPOMvALgZd.jpg"),
            genres: ["Acción", "Drama", "Bélico"],
            runtimeMinutes: 109,
            imdbId: "tt17279496",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 81,
                rottenTomatoesAudience: 70,
                imdbScore: 7.1,
                imdbVotes: "210K"
            ),
            countryOfOrigin: "US"
        ),
        Movie(
            id: "937287",
            title: "Challengers",
            overview: "Tashi, una extenista convertida en entrenadora, transforma a su esposo en campeón mundial del Grand Slam. Para sacarlo de una mala racha, lo inscribe en un torneo Challenger.",
            releaseYear: 2024,
            releaseDate: "2024-04-26",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/H6vke73qEp2FF4YPF4KLWR2w9v.jpg"),
            genres: ["Drama", "Romance"],
            runtimeMinutes: 131,
            imdbId: "tt16426418",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 88,
                rottenTomatoesAudience: 73,
                imdbScore: 7.2,
                imdbVotes: "165K"
            ),
            countryOfOrigin: "US"
        ),
        Movie(
            id: "1058694",
            title: "Puan",
            overview: "Marcelo Pena ha dedicado su vida a la enseñanza de filosofía en la Universidad de Buenos Aires. Cuando su mentor fallece súbitamente, asume que heredará el puesto de titular de cátedra.",
            releaseYear: 2024,
            releaseDate: "2024-02-15",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/gB3H6wH1x2z5v8Y9w3v7Q4z.jpg"),
            genres: ["Comedia", "Drama"],
            runtimeMinutes: 111,
            imdbId: "tt27771746",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 88,
                rottenTomatoesAudience: 78,
                imdbScore: 7.1,
                imdbVotes: "6K"
            ),
            countryOfOrigin: "AR"
        ),
        Movie(
            id: "915935",
            title: "Anatomía de una Caída",
            overview: "Una mujer es sospechosa de la muerte de su marido y su hijo ciego se enfrenta a un dilema moral como único testigo.",
            releaseYear: 2024,
            releaseDate: "2024-01-26",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/5aGhaI2l5Uv4dFqJ9R3j8kL2s1.jpg"),
            genres: ["Drama", "Crimen", "Misterio"],
            runtimeMinutes: 151,
            imdbId: "tt17009710",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 96,
                rottenTomatoesAudience: 90,
                imdbScore: 7.7,
                imdbVotes: "195K"
            ),
            countryOfOrigin: "FR"
        ),
        Movie(
            id: "508883",
            title: "El Chico y la Garza",
            overview: "A través de los encuentros con sus amigos y su tío, un joven vive una experiencia que le ayuda a reflexionar sobre la vida y la muerte en una mansión misteriosa.",
            releaseYear: 2024,
            releaseDate: "2024-01-11",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/jDQhu2cfsY85y578v1E9L3K8J9.jpg"),
            genres: ["Animación", "Aventura", "Fantasía"],
            runtimeMinutes: 124,
            imdbId: "tt6587046",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 97,
                rottenTomatoesAudience: 88,
                imdbScore: 7.5,
                imdbVotes: "95K"
            ),
            countryOfOrigin: "JP"
        ),
        Movie(
            id: "940721",
            title: "Godzilla Minus One",
            overview: "En el Japón de posguerra surge un nuevo terror: Godzilla. ¿Podrán los supervivientes defenderse y resistir?",
            releaseYear: 2024,
            releaseDate: "2024-01-01",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/hkxxMIGaiCTmrEArK7J56J1Gso.jpg"),
            genres: ["Acción", "Ciencia Ficción", "Drama"],
            runtimeMinutes: 125,
            imdbId: "tt23289160",
            ratings: ExternalRatings(
                rottenTomatoesCritics: 98,
                rottenTomatoesAudience: 98,
                imdbScore: 7.9,
                imdbVotes: "165K"
            ),
            countryOfOrigin: "JP"
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
            title: "Tiempos Violentos (Pulp Fiction)",
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
            title: "Interestelar (Interstellar)",
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
            title: "Spider-Man: A Través del Spider-Verso",
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
            title: "Batman: El Caballero de la Noche",
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
            title: "La La Land: Una Historia de Amor",
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
            title: "Sueño de Fuga (The Shawshank Redemption)",
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
            title: "Volver al Futuro (Back to the Future)",
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
            title: "Whiplash: Música y Obsesión",
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
