import Foundation

/// Implementación del servicio de cartelera local basada en catálogo curado y extensible a APIs de producción
public actor ShowtimesServiceImpl: ShowtimesServiceProtocol {
    
    public init() {}
    
    nonisolated public func getAvailableCities() -> [UserLocation] {
        return [
            UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            UserLocation(city: "Barcelona", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true),
            UserLocation(city: "Ciudad de México", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", isLocal: true),
            UserLocation(city: "Bogotá", country: "Colombia", countryCode: "CO", flagEmoji: "🇨🇴", isLocal: true),
            UserLocation(city: "Buenos Aires", country: "Argentina", countryCode: "AR", flagEmoji: "🇦🇷", isLocal: true),
            UserLocation(city: "Santiago", country: "Chile", countryCode: "CL", flagEmoji: "🇨🇱", isLocal: true),
            UserLocation(city: "Lima", country: "Perú", countryCode: "PE", flagEmoji: "🇵🇪", isLocal: true)
        ]
    }
    
    public func getMoviesInTheaters(city: String, countryCode: String) async throws -> [String: [CinemaShowtime]] {
        let normalizedCity = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        switch normalizedCity {
        case "madrid":
            return [
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Kinépolis Madrid Ciudad de la Imagen", city: "Madrid", roomFormat: "IMAX Laser 3D", times: ["16:30", "19:45", "22:30"]),
                    CinemaShowtime(cinemaName: "Yelmo Cines Ideal", city: "Madrid", roomFormat: "Sala 2 (VOSE)", times: ["17:00", "20:15"]),
                    CinemaShowtime(cinemaName: "Cinesa Proyecciones", city: "Madrid", roomFormat: "iSense Dolby Atmos", times: ["18:15", "21:30"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinesa Proyecciones", city: "Madrid", roomFormat: "Digital 2D", times: ["16:00", "18:00", "20:00"]),
                    CinemaShowtime(cinemaName: "Cines Verdi", city: "Madrid", roomFormat: "VOSE", times: ["17:15", "19:30"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Kinépolis Madrid", city: "Madrid", roomFormat: "4DX 3D", times: ["17:15", "20:30", "23:15"]),
                    CinemaShowtime(cinemaName: "Cines Callao", city: "Madrid", roomFormat: "Gran Sala", times: ["19:00", "21:45"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Yelmo Cines Ideal", city: "Madrid", roomFormat: "VOSE Dolby Atmos", times: ["18:30", "21:00", "23:20"]),
                    CinemaShowtime(cinemaName: "Cinesa Méndez Álvaro", city: "Madrid", roomFormat: "iSense", times: ["19:15", "22:00"])
                ]
            ]
            
        case "barcelona":
            return [
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Phenomena Experience", city: "Barcelona", roomFormat: "70mm / Dolby Atmos", times: ["18:00", "21:30"]),
                    CinemaShowtime(cinemaName: "Cinesa Diagonal Mar", city: "Barcelona", roomFormat: "IMAX Laser", times: ["16:45", "20:00", "22:50"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinesa La Maquinista", city: "Barcelona", roomFormat: "Dolby Cinema", times: ["16:15", "18:30"]),
                    CinemaShowtime(cinemaName: "Renoir Floridablanca", city: "Barcelona", roomFormat: "VOSE", times: ["17:00", "19:15"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Cinesa Diagonal", city: "Barcelona", roomFormat: "iSense 2D", times: ["17:30", "20:45", "23:00"]),
                    CinemaShowtime(cinemaName: "Yelmo Cines Comedia", city: "Barcelona", roomFormat: "VOSE", times: ["18:15", "21:00"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Phenomena Experience", city: "Barcelona", roomFormat: "Sala Principal 4K", times: ["19:30", "22:15"]),
                    CinemaShowtime(cinemaName: "Cinesa Diagonal Mar", city: "Barcelona", roomFormat: "iSense", times: ["18:45", "21:30"])
                ]
            ]
            
        case "ciudad de méxico", "cdmx", "mexico", "méxico":
            return [
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Cinépolis Diana", city: "Ciudad de México", roomFormat: "IMAX Laser (Sub)", times: ["15:45", "19:00", "22:15"]),
                    CinemaShowtime(cinemaName: "Cineteca Nacional", city: "Ciudad de México", roomFormat: "Sala 1 Jorge Stahl", times: ["17:30", "20:30"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinépolis Universidad", city: "Ciudad de México", roomFormat: "Sala Junior / 2D", times: ["14:00", "16:20", "18:40"]),
                    CinemaShowtime(cinemaName: "Cinemex Reforma 222", city: "Ciudad de México", roomFormat: "Platino 2D", times: ["17:00", "19:20"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Cinépolis Perisur", city: "Ciudad de México", roomFormat: "4DX 3D", times: ["16:30", "19:30", "22:30"]),
                    CinemaShowtime(cinemaName: "Cinemex Antara Polanco", city: "Ciudad de México", roomFormat: "Platino Atmos", times: ["18:15", "21:15"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Cinépolis Diana", city: "Ciudad de México", roomFormat: "Macro XE Atmos", times: ["18:00", "20:45", "23:15"]),
                    CinemaShowtime(cinemaName: "Cinemex Reforma 222", city: "Ciudad de México", roomFormat: "Platino (Sub)", times: ["19:15", "22:00"])
                ]
            ]
            
        case "bogotá", "bogota":
            return [
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Cine Colombia Centro Mayor", city: "Bogotá", roomFormat: "MegaSala IMAX", times: ["16:00", "19:30", "22:15"]),
                    CinemaShowtime(cinemaName: "Cinemateca de Bogotá", city: "Bogotá", roomFormat: "Sala Capital", times: ["18:00", "21:00"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cine Colombia Andino", city: "Bogotá", roomFormat: "Dinamix 3D", times: ["15:00", "17:15", "19:30"]),
                    CinemaShowtime(cinemaName: "Procinal Plaza Central", city: "Bogotá", roomFormat: "Sala 2D", times: ["14:30", "16:45"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Cine Colombia Titan Plaza", city: "Bogotá", roomFormat: "MegaSala Atmos", times: ["17:00", "20:00", "22:45"]),
                    CinemaShowtime(cinemaName: "Cinemark Multiplaza", city: "Bogotá", roomFormat: "XD 2D", times: ["18:30", "21:15"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Cine Colombia Andino", city: "Bogotá", roomFormat: "Sala Prime (Sub)", times: ["18:45", "21:30"]),
                    CinemaShowtime(cinemaName: "Cinemark Atlantis", city: "Bogotá", roomFormat: "Sala Premier", times: ["19:15", "22:00"])
                ]
            ]
            
        case "buenos aires":
            return [
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Hoyts Abasto", city: "Buenos Aires", roomFormat: "Sala 4DX", times: ["16:40", "20:00", "22:50"]),
                    CinemaShowtime(cinemaName: "Cine Gaumont", city: "Buenos Aires", roomFormat: "Sala 1 Espacio INCAA", times: ["17:30", "20:30"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinemark Palermo", city: "Buenos Aires", roomFormat: "XD 2D", times: ["15:30", "17:45", "20:00"]),
                    CinemaShowtime(cinemaName: "Hoyts Dot Baires", city: "Buenos Aires", roomFormat: "Sala Premium", times: ["16:15", "18:30"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Hoyts Abasto", city: "Buenos Aires", roomFormat: "DBOX 2D", times: ["17:15", "20:15", "23:00"]),
                    CinemaShowtime(cinemaName: "Cinemark Caballito", city: "Buenos Aires", roomFormat: "Sala 3 (Sub)", times: ["18:30", "21:30"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Cinemark Palermo", city: "Buenos Aires", roomFormat: "XD Atmos (Sub)", times: ["19:00", "21:45"]),
                    CinemaShowtime(cinemaName: "Hoyts Dot Baires", city: "Buenos Aires", roomFormat: "Premium Class", times: ["18:45", "22:00"])
                ]
            ]
            
        case "santiago":
            return [
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Cine Hoyts Parque Arauco", city: "Santiago", roomFormat: "IMAX Laser", times: ["16:30", "20:00", "22:45"]),
                    CinemaShowtime(cinemaName: "Cineteca Nacional de Chile", city: "Santiago", roomFormat: "Sala de Cine", times: ["18:00", "20:45"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinemark Alto Las Condes", city: "Santiago", roomFormat: "XD 2D", times: ["15:00", "17:15", "19:30"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Cineplanet Costanera Center", city: "Santiago", roomFormat: "Sala Xtreme Atmos", times: ["17:30", "20:30", "23:00"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Cinemark Mallplaza Egaña", city: "Santiago", roomFormat: "IMAX 2D (Sub)", times: ["19:15", "22:00"])
                ]
            ]
            
        case "lima":
            return [
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Cineplanet Alcázar", city: "Lima", roomFormat: "Prime 2D (Sub)", times: ["16:40", "20:10"]),
                    CinemaShowtime(cinemaName: "Cinemark Jockey Plaza", city: "Lima", roomFormat: "XD Dolby Atmos", times: ["17:00", "20:30", "23:15"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cineplanet San Miguel", city: "Lima", roomFormat: "2D Doblada", times: ["14:30", "16:45", "19:00"]),
                    CinemaShowtime(cinemaName: "Cinemark San Miguel", city: "Lima", roomFormat: "XD 2D", times: ["15:15", "17:30"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Cinemark Jockey Plaza", city: "Lima", roomFormat: "XD 3D", times: ["16:30", "19:30", "22:20"]),
                    CinemaShowtime(cinemaName: "Cineplanet Mall del Sur", city: "Lima", roomFormat: "Xtreme 2D", times: ["18:00", "21:00"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Cineplanet Alcázar", city: "Lima", roomFormat: "Prime (Sub)", times: ["18:50", "21:40"]),
                    CinemaShowtime(cinemaName: "Cinemark Open Plaza Angamos", city: "Lima", roomFormat: "XD 2D", times: ["19:20", "22:10"])
                ]
            ]
            
        default:
            // Fallback genérico para cualquier otra ciudad seleccionada
            return [
                "693134": [
                    CinemaShowtime(cinemaName: "Cine Central", city: city, roomFormat: "Digital 2D", times: ["17:00", "20:30"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: "Cine Central", city: city, roomFormat: "Digital 2D", times: ["16:00", "18:15"])
                ],
                "533535": [
                    CinemaShowtime(cinemaName: "Cine Central", city: city, roomFormat: "Digital 2D", times: ["18:00", "21:15"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: "Cine Central", city: city, roomFormat: "Digital 2D", times: ["19:00", "22:00"])
                ]
            ]
        }
    }
    
    public func getShowtimes(forMovieId movieId: String, city: String) async throws -> [CinemaShowtime] {
        let cityMovies = try await getMoviesInTheaters(city: city, countryCode: "")
        return cityMovies[movieId] ?? []
    }
}
