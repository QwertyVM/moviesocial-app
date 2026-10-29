import Foundation

/// Implementación del servicio de cartelera local basada en catálogo curado y extensible a APIs de producción
public actor ShowtimesServiceImpl: ShowtimesServiceProtocol {
    
    public init() {}
    
    nonisolated public func getAvailableCities() -> [UserLocation] {
        return [
            UserLocation(city: "Ciudad de México", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", isLocal: true, area: "CDMX / Valle de México"),
            UserLocation(city: "Bogotá", country: "Colombia", countryCode: "CO", flagEmoji: "🇨🇴", isLocal: true, area: "Bogotá D.C."),
            UserLocation(city: "Buenos Aires", country: "Argentina", countryCode: "AR", flagEmoji: "🇦🇷", isLocal: true, area: "CABA"),
            UserLocation(city: "Santiago", country: "Chile", countryCode: "CL", flagEmoji: "🇨🇱", isLocal: true, area: "Región Metropolitana"),
            UserLocation(city: "Lima", country: "Perú", countryCode: "PE", flagEmoji: "🇵🇪", isLocal: true, area: "Lima Metropolitana"),
            UserLocation(city: "Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true, area: "Comunidad de Madrid"),
            UserLocation(city: "Barcelona", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", isLocal: true, area: "Cataluña"),
            UserLocation(city: "Los Ángeles", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", isLocal: true, area: "California"),
            UserLocation(city: "Nueva York", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", isLocal: true, area: "New York"),
            UserLocation(city: "París", country: "Francia", countryCode: "FR", flagEmoji: "🇫🇷", isLocal: true, area: "Île-de-France"),
            UserLocation(city: "Tokio", country: "Japón", countryCode: "JP", flagEmoji: "🇯🇵", isLocal: true, area: "Kanto"),
            UserLocation(city: "Londres", country: "Reino Unido", countryCode: "GB", flagEmoji: "🇬🇧", isLocal: true, area: "Greater London"),
            UserLocation(city: "Roma", country: "Italia", countryCode: "IT", flagEmoji: "🇮🇹", isLocal: true, area: "Lacio"),
            UserLocation(city: "Berlín", country: "Alemania", countryCode: "DE", flagEmoji: "🇩🇪", isLocal: true, area: "Berlín")
        ]
    }
    
    nonisolated public func getAvailableCountryGroups() -> [CountryAreaGroup] {
        return [
            CountryAreaGroup(
                country: "España",
                countryCode: "ES",
                flagEmoji: "🇪🇸",
                areas: [
                    AreaLocation(city: "Madrid", area: "Comunidad de Madrid", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", prominentTheaters: ["Kinépolis", "Yelmo Ideal", "Cinesa Proyecciones", "Cineteca"]),
                    AreaLocation(city: "Barcelona", area: "Cataluña", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", prominentTheaters: ["Phenomena Experience", "Cinesa Diagonal Mar", "Renoir Floridablanca", "Verdi"]),
                    AreaLocation(city: "Valencia", area: "Comunidad Valenciana", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", prominentTheaters: ["Cines Lys", "Kinépolis Valencia", "Yelmo Campanar"]),
                    AreaLocation(city: "Sevilla", area: "Andalucía", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", prominentTheaters: ["Cinesur Nervión Plaza", "Cine Cervantes", "Avenida"]),
                    AreaLocation(city: "Bilbao", area: "País Vasco", country: "España", countryCode: "ES", flagEmoji: "🇪🇸", prominentTheaters: ["Golem Alhóndiga", "Cinesa Zubiarte"])
                ]
            ),
            CountryAreaGroup(
                country: "México",
                countryCode: "MX",
                flagEmoji: "🇲🇽",
                areas: [
                    AreaLocation(city: "Ciudad de México", area: "CDMX / Valle de México", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", prominentTheaters: ["Cinépolis Diana", "Cinemex Reforma 222", "Cineteca Nacional", "Cine Tonalá"]),
                    AreaLocation(city: "Guadalajara", area: "Jalisco", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", prominentTheaters: ["Cinépolis VIP Andares", "Cineteca FICG", "Cinemex Sao Paulo"]),
                    AreaLocation(city: "Monterrey", area: "Nuevo León", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", prominentTheaters: ["Cinépolis Galerías Monterrey", "Cinemex Paseo San Pedro", "Cineteca NL"]),
                    AreaLocation(city: "Cancún", area: "Quintana Roo", country: "México", countryCode: "MX", flagEmoji: "🇲🇽", prominentTheaters: ["Cinépolis Plaza Las Américas", "Cinemex Malecón"])
                ]
            ),
            CountryAreaGroup(
                country: "Estados Unidos",
                countryCode: "US",
                flagEmoji: "🇺🇸",
                areas: [
                    AreaLocation(city: "Los Ángeles", area: "California", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", prominentTheaters: ["TCL Chinese Theatre IMAX 70mm", "AMC The Grove", "Landmark Sunset"]),
                    AreaLocation(city: "Nueva York", area: "New York", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", prominentTheaters: ["AMC Lincoln Square IMAX", "Alamo Drafthouse Brooklyn", "Angelika Film Center"]),
                    AreaLocation(city: "Miami", area: "Florida", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", prominentTheaters: ["Silverspot Cinema", "AMC Aventura 24", "O Cinema South Beach"]),
                    AreaLocation(city: "San Francisco", area: "California", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", prominentTheaters: ["Alamo Drafthouse New Mission", "AMC Metreon 16 IMAX", "Castro Theatre"]),
                    AreaLocation(city: "Chicago", area: "Illinois", country: "Estados Unidos", countryCode: "US", flagEmoji: "🇺🇸", prominentTheaters: ["Music Box Theatre", "AMC River East 21", "Gene Siskel Film Center"])
                ]
            ),
            CountryAreaGroup(
                country: "Argentina",
                countryCode: "AR",
                flagEmoji: "🇦🇷",
                areas: [
                    AreaLocation(city: "Buenos Aires", area: "CABA / AMBA", country: "Argentina", countryCode: "AR", flagEmoji: "🇦🇷", prominentTheaters: ["Cine Gaumont Espacio INCAA", "Hoyts Abasto", "Malba Cine", "Cinemark Palermo"]),
                    AreaLocation(city: "Córdoba", area: "Córdoba", country: "Argentina", countryCode: "AR", flagEmoji: "🇦🇷", prominentTheaters: ["Hoyts Patio Olmos", "Cineclub Municipal Hugo del Carril", "Showcase Villa Cabrera"]),
                    AreaLocation(city: "Rosario", area: "Santa Fe", country: "Argentina", countryCode: "AR", flagEmoji: "🇦🇷", prominentTheaters: ["El Cairo Cine Público", "Showcase Rosario", "Cines del Centro"])
                ]
            ),
            CountryAreaGroup(
                country: "Colombia",
                countryCode: "CO",
                flagEmoji: "🇨🇴",
                areas: [
                    AreaLocation(city: "Bogotá", area: "Bogotá D.C.", country: "Colombia", countryCode: "CO", flagEmoji: "🇨🇴", prominentTheaters: ["Cine Colombia Centro Mayor MegaSala", "Cinemateca de Bogotá", "Cine Colombia Andino", "Cinemark Multiplaza"]),
                    AreaLocation(city: "Medellín", area: "Antioquia", country: "Colombia", countryCode: "CO", flagEmoji: "🇨🇴", prominentTheaters: ["Cine Colombia Viva Envigado", "Colombo Americano", "Procinal Mayorca"]),
                    AreaLocation(city: "Cali", area: "Valle del Cauca", country: "Colombia", countryCode: "CO", flagEmoji: "🇨🇴", prominentTheaters: ["Cinemark Mallplaza Cali", "Cine Colombia Chipichape", "Cinemateca La Tertulia"])
                ]
            ),
            CountryAreaGroup(
                country: "Chile",
                countryCode: "CL",
                flagEmoji: "🇨🇱",
                areas: [
                    AreaLocation(city: "Santiago", area: "Región Metropolitana", country: "Chile", countryCode: "CL", flagEmoji: "🇨🇱", prominentTheaters: ["Cine Hoyts Parque Arauco", "Cineteca Nacional de Chile", "Cineplanet Costanera Center", "Cinemark Mallplaza Egaña"]),
                    AreaLocation(city: "Valparaíso", area: "Valparaíso / Viña del Mar", country: "Chile", countryCode: "CL", flagEmoji: "🇨🇱", prominentTheaters: ["Cine Hoyts Valparaíso", "Cinemark Marina Arauco", "Cine Condell"]),
                    AreaLocation(city: "Concepción", area: "Biobío", country: "Chile", countryCode: "CL", flagEmoji: "🇨🇱", prominentTheaters: ["Cineplanet Mall del Centro", "Cinemark Mirador Biobío"])
                ]
            ),
            CountryAreaGroup(
                country: "Perú",
                countryCode: "PE",
                flagEmoji: "🇵🇪",
                areas: [
                    AreaLocation(city: "Lima", area: "Lima Metropolitana", country: "Perú", countryCode: "PE", flagEmoji: "🇵🇪", prominentTheaters: ["Cineplanet Alcázar Prime", "Cinemark Jockey Plaza XD", "CCPUCP Lima", "Cineplanet San Miguel"]),
                    AreaLocation(city: "Arequipa", area: "Arequipa", country: "Perú", countryCode: "PE", flagEmoji: "🇵🇪", prominentTheaters: ["Cineplanet Mall Arequipa", "Cinemark Parque Lambramani"]),
                    AreaLocation(city: "Cusco", area: "Cusco", country: "Perú", countryCode: "PE", flagEmoji: "🇵🇪", prominentTheaters: ["Cineplanet Real Plaza Cusco"])
                ]
            ),
            CountryAreaGroup(
                country: "Francia",
                countryCode: "FR",
                flagEmoji: "🇫🇷",
                areas: [
                    AreaLocation(city: "París", area: "Île-de-France", country: "Francia", countryCode: "FR", flagEmoji: "🇫🇷", prominentTheaters: ["Grand Rex 70mm", "MK2 Bibliothèque", "UGC Ciné Cité Les Halles", "Le Champo"]),
                    AreaLocation(city: "Lyon", area: "Auvergne-Rhône-Alpes", country: "Francia", countryCode: "FR", flagEmoji: "🇫🇷", prominentTheaters: ["Pathé Bellecour", "Institut Lumière", "UGC Ciné Cité Confluence"])
                ]
            ),
            CountryAreaGroup(
                country: "Japón",
                countryCode: "JP",
                flagEmoji: "🇯🇵",
                areas: [
                    AreaLocation(city: "Tokio", area: "Kanto", country: "Japón", countryCode: "JP", flagEmoji: "🇯🇵", prominentTheaters: ["TOHO Cinemas Shinjuku", "109 Cinemas Premium Shinjuku", "Grand Cinema Sunshine Ikebukuro"]),
                    AreaLocation(city: "Osaka", area: "Kansai", country: "Japón", countryCode: "JP", flagEmoji: "🇯🇵", prominentTheaters: ["TOHO Cinemas Umeda", "Osaka Station City Cinema", "Cinema Mart"])
                ]
            ),
            CountryAreaGroup(
                country: "Reino Unido",
                countryCode: "GB",
                flagEmoji: "🇬🇧",
                areas: [
                    AreaLocation(city: "Londres", area: "Greater London", country: "Reino Unido", countryCode: "GB", flagEmoji: "🇬🇧", prominentTheaters: ["BFI IMAX Waterloo", "Odeon Luxe Leicester Square", "Curzon Soho"]),
                    AreaLocation(city: "Mánchester", area: "Greater Manchester", country: "Reino Unido", countryCode: "GB", flagEmoji: "🇬🇧", prominentTheaters: ["Vue Printworks IMAX", "HOME Manchester"])
                ]
            ),
            CountryAreaGroup(
                country: "Alemania",
                countryCode: "DE",
                flagEmoji: "🇩🇪",
                areas: [
                    AreaLocation(city: "Berlín", area: "Berlín", country: "Alemania", countryCode: "DE", flagEmoji: "🇩🇪", prominentTheaters: ["Zoo Palast", "Kino International", "CineStar Potsdamer Platz"]),
                    AreaLocation(city: "Múnich", area: "Baviera", country: "Alemania", countryCode: "DE", flagEmoji: "🇩🇪", prominentTheaters: ["Mathäser Filmpalast", "Astor Film Lounge"])
                ]
            ),
            CountryAreaGroup(
                country: "Italia",
                countryCode: "IT",
                flagEmoji: "🇮🇹",
                areas: [
                    AreaLocation(city: "Roma", area: "Lacio", country: "Italia", countryCode: "IT", flagEmoji: "🇮🇹", prominentTheaters: ["Cinema Barberini 4K", "The Space Cinema Moderno", "Nuovo Sacher"]),
                    AreaLocation(city: "Milán", area: "Lombardía", country: "Italia", countryCode: "IT", flagEmoji: "🇮🇹", prominentTheaters: ["Cinema Anteo Palazzo del Cinema", "UCI Cinemas Bicocca"])
                ]
            )
        ]
    }
    
    public func getMoviesInTheaters(city: String, countryCode: String) async throws -> [String: [CinemaShowtime]] {
        let normalizedCity = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCode = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 1. ESPAÑA
        if normalizedCity == "madrid" {
            return [
                "939335": [ // La Sociedad de la Nieve
                    CinemaShowtime(cinemaName: "Cines Verdi", city: "Madrid", roomFormat: "Sala 1 4K Atmos", times: ["17:00", "19:45", "22:15"]),
                    CinemaShowtime(cinemaName: "Cineteca Madrid", city: "Madrid", roomFormat: "Sala Azcona", times: ["18:30", "21:00"]),
                    CinemaShowtime(cinemaName: "Cines Callao", city: "Madrid", roomFormat: "Gran Sala", times: ["20:00", "22:45"])
                ],
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Kinépolis Madrid Ciudad de la Imagen", city: "Madrid", roomFormat: "IMAX Laser 3D", times: ["16:30", "19:45", "22:30"]),
                    CinemaShowtime(cinemaName: "Yelmo Cines Ideal", city: "Madrid", roomFormat: "Sala 2 (VOSE)", times: ["17:00", "20:15"]),
                    CinemaShowtime(cinemaName: "Cinesa Proyecciones", city: "Madrid", roomFormat: "iSense Dolby Atmos", times: ["18:15", "21:30"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinesa Proyecciones", city: "Madrid", roomFormat: "Digital 2D", times: ["16:00", "18:00", "20:00"]),
                    CinemaShowtime(cinemaName: "Cines Verdi", city: "Madrid", roomFormat: "VOSE", times: ["17:15", "19:30"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Yelmo Cines Ideal", city: "Madrid", roomFormat: "VOSE Dolby Atmos", times: ["18:30", "21:00", "23:20"]),
                    CinemaShowtime(cinemaName: "Cinesa Méndez Álvaro", city: "Madrid", roomFormat: "iSense", times: ["19:15", "22:00"])
                ]
            ]
        } else if normalizedCity == "barcelona" {
            return [
                "939335": [ // La Sociedad de la Nieve
                    CinemaShowtime(cinemaName: "Phenomena Experience", city: "Barcelona", roomFormat: "Gran Pantalla 4K", times: ["17:30", "20:45"]),
                    CinemaShowtime(cinemaName: "Renoir Floridablanca", city: "Barcelona", roomFormat: "VOSE", times: ["18:15", "21:00"])
                ],
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Phenomena Experience", city: "Barcelona", roomFormat: "70mm / Dolby Atmos", times: ["18:00", "21:30"]),
                    CinemaShowtime(cinemaName: "Cinesa Diagonal Mar", city: "Barcelona", roomFormat: "IMAX Laser", times: ["16:45", "20:00", "22:50"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinesa La Maquinista", city: "Barcelona", roomFormat: "Dolby Cinema", times: ["16:15", "18:30"]),
                    CinemaShowtime(cinemaName: "Renoir Floridablanca", city: "Barcelona", roomFormat: "VOSE", times: ["17:00", "19:15"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Phenomena Experience", city: "Barcelona", roomFormat: "Sala Principal 4K", times: ["19:30", "22:15"]),
                    CinemaShowtime(cinemaName: "Cinesa Diagonal Mar", city: "Barcelona", roomFormat: "iSense", times: ["18:45", "21:30"])
                ]
            ]
        } else if normalizedCode == "ES" || ["valencia", "sevilla", "bilbao"].contains(normalizedCity) {
            let mainTheaters = normalizedCity == "valencia" ? ["Cines Lys", "Kinépolis Valencia"] :
                               normalizedCity == "sevilla" ? ["Cinesur Nervión Plaza", "Cine Cervantes"] :
                               normalizedCity == "bilbao" ? ["Golem Alhóndiga", "Cinesa Zubiarte"] : ["Cinesa Local", "Yelmo Cines"]
            return [
                "939335": [
                    CinemaShowtime(cinemaName: mainTheaters[0], city: city, roomFormat: "Digital 4K", times: ["17:30", "20:15"])
                ],
                "693134": [
                    CinemaShowtime(cinemaName: mainTheaters[0], city: city, roomFormat: "iSense Atmos", times: ["18:00", "21:15"]),
                    CinemaShowtime(cinemaName: mainTheaters[1], city: city, roomFormat: "VOSE", times: ["17:00", "20:30"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: mainTheaters[1], city: city, roomFormat: "Digital 2D", times: ["16:00", "18:15"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: mainTheaters[0], city: city, roomFormat: "Sala Dolby", times: ["19:00", "21:45"])
                ]
            ]
        }
        
        // 2. MÉXICO
        if ["ciudad de méxico", "cdmx", "mexico", "m\u{e9}xico"].contains(normalizedCity) {
            return [
                "1032823": [ // Radical
                    CinemaShowtime(cinemaName: "Cineteca Nacional", city: "Ciudad de México", roomFormat: "Sala 1 Jorge Stahl", times: ["16:30", "19:00", "21:30"]),
                    CinemaShowtime(cinemaName: "Cine Tonalá", city: "Ciudad de México", roomFormat: "Sala Cineclub", times: ["18:00", "20:30"]),
                    CinemaShowtime(cinemaName: "Cinemex Platino", city: "Ciudad de México", roomFormat: "Platino 2D", times: ["17:15", "19:45"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: "Cinépolis Diana", city: "Ciudad de México", roomFormat: "4DX 3D", times: ["16:30", "19:30", "22:30"]),
                    CinemaShowtime(cinemaName: "Cinemex Antara Polanco", city: "Ciudad de México", roomFormat: "Platino Atmos", times: ["18:15", "21:15"])
                ],
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: "Cinépolis Diana", city: "Ciudad de México", roomFormat: "IMAX Laser (Sub)", times: ["15:45", "19:00", "22:15"]),
                    CinemaShowtime(cinemaName: "Cineteca Nacional", city: "Ciudad de México", roomFormat: "Sala 3 Gabriel Figueroa", times: ["17:30", "20:30"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: "Cinépolis Universidad", city: "Ciudad de México", roomFormat: "Sala Junior / 2D", times: ["14:00", "16:20", "18:40"]),
                    CinemaShowtime(cinemaName: "Cinemex Reforma 222", city: "Ciudad de México", roomFormat: "Platino 2D", times: ["17:00", "19:20"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: "Cinépolis Diana", city: "Ciudad de México", roomFormat: "Macro XE Atmos", times: ["18:00", "20:45", "23:15"]),
                    CinemaShowtime(cinemaName: "Cinemex Reforma 222", city: "Ciudad de México", roomFormat: "Platino (Sub)", times: ["19:15", "22:00"])
                ]
            ]
        } else if normalizedCode == "MX" || ["guadalajara", "monterrey", "cancún", "cancun"].contains(normalizedCity) {
            let primary = normalizedCity == "guadalajara" ? "Cinépolis VIP Andares" :
                          normalizedCity == "monterrey" ? "Cinépolis Galerías Monterrey" : "Cinépolis Plaza Las Américas"
            let secondary = normalizedCity == "guadalajara" ? "Cineteca FICG" :
                            normalizedCity == "monterrey" ? "Cinemex Paseo San Pedro" : "Cinemex Malecón"
            return [
                "1032823": [
                    CinemaShowtime(cinemaName: secondary, city: city, roomFormat: "Sala de Autor", times: ["17:00", "19:30"])
                ],
                "533535": [
                    CinemaShowtime(cinemaName: primary, city: city, roomFormat: "4DX / Macro XE", times: ["16:45", "19:45", "22:30"])
                ],
                "693134": [
                    CinemaShowtime(cinemaName: primary, city: city, roomFormat: "IMAX Laser", times: ["16:00", "19:15", "22:20"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: primary, city: city, roomFormat: "Digital 2D", times: ["15:00", "17:15", "19:30"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: secondary, city: city, roomFormat: "Platino Sub", times: ["18:30", "21:15"])
                ]
            ]
        }
        
        // 3. ESTADOS UNIDOS
        if normalizedCode == "US" || ["los ángeles", "los angeles", "nueva york", "new york", "miami", "san francisco", "chicago"].contains(normalizedCity) {
            let c1 = normalizedCity.contains("angeles") ? "TCL Chinese Theatre IMAX 70mm" :
                     normalizedCity.contains("york") ? "AMC Lincoln Square IMAX" :
                     normalizedCity.contains("francisco") ? "Alamo Drafthouse New Mission" :
                     normalizedCity.contains("chicago") ? "Music Box Theatre" : "Silverspot Cinema Downtown"
            let c2 = normalizedCity.contains("angeles") ? "AMC The Grove 14" :
                     normalizedCity.contains("york") ? "Angelika Film Center" :
                     normalizedCity.contains("francisco") ? "AMC Metreon 16 IMAX" :
                     normalizedCity.contains("chicago") ? "AMC River East 21" : "AMC Aventura 24"
            
            return [
                "929590": [ // Civil War
                    CinemaShowtime(cinemaName: c1, city: city, roomFormat: "IMAX Laser", times: ["16:15", "19:00", "21:45"]),
                    CinemaShowtime(cinemaName: c2, city: city, roomFormat: "Dolby Cinema", times: ["18:30", "21:15"])
                ],
                "937287": [ // Challengers
                    CinemaShowtime(cinemaName: c2, city: city, roomFormat: "Digital 4K", times: ["17:00", "19:45", "22:15"]),
                    CinemaShowtime(cinemaName: c1, city: city, roomFormat: "Standard 2D", times: ["18:00", "20:45"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: c1, city: city, roomFormat: "Prime 3D", times: ["17:30", "20:30", "23:15"]),
                    CinemaShowtime(cinemaName: c2, city: city, roomFormat: "Dolby Atmos", times: ["16:45", "19:30"])
                ],
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: c1, city: city, roomFormat: "70mm IMAX Special Engagement", times: ["18:15", "21:45"])
                ],
                "945961": [ // Alien: Romulus
                    CinemaShowtime(cinemaName: c2, city: city, roomFormat: "IMAX Laser", times: ["19:15", "22:00"])
                ]
            ]
        }
        
        // 4. ARGENTINA
        if normalizedCode == "AR" || ["buenos aires", "córdoba", "cordoba", "rosario"].contains(normalizedCity) {
            let main1 = normalizedCity.contains("aires") ? "Cine Gaumont Espacio INCAA" :
                        normalizedCity.contains("cordoba") ? "Cineclub Municipal Hugo del Carril" : "El Cairo Cine Público"
            let main2 = normalizedCity.contains("aires") ? "Hoyts Abasto" :
                        normalizedCity.contains("cordoba") ? "Hoyts Patio Olmos" : "Showcase Cines Rosario"
            return [
                "1058694": [ // Puan
                    CinemaShowtime(cinemaName: main1, city: city, roomFormat: "Sala 1 Espacio INCAA", times: ["17:00", "19:30", "21:45"]),
                    CinemaShowtime(cinemaName: main2, city: city, roomFormat: "Sala 2D Nacional", times: ["18:15", "20:30"])
                ],
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: main2, city: city, roomFormat: "Sala 4DX / XD", times: ["16:40", "20:00", "22:50"]),
                    CinemaShowtime(cinemaName: main1, city: city, roomFormat: "Sala 2", times: ["18:00", "21:00"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: main2, city: city, roomFormat: "XD 2D", times: ["15:30", "17:45", "20:00"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: main2, city: city, roomFormat: "DBOX 2D", times: ["17:15", "20:15", "23:00"])
                ]
            ]
        }
        
        // 5. FRANCIA
        if normalizedCode == "FR" || ["parís", "paris", "lyon"].contains(normalizedCity) {
            let f1 = normalizedCity.contains("lyon") ? "Pathé Bellecour" : "Grand Rex 70mm"
            let f2 = normalizedCity.contains("lyon") ? "Institut Lumière" : "MK2 Bibliothèque"
            return [
                "915935": [ // Anatomía de una Caída
                    CinemaShowtime(cinemaName: f2, city: city, roomFormat: "Salle d'Auteur 4K", times: ["17:15", "20:00", "22:30"]),
                    CinemaShowtime(cinemaName: f1, city: city, roomFormat: "Séance Spéciale", times: ["18:30", "21:15"])
                ],
                "693134": [ // Dune 2
                    CinemaShowtime(cinemaName: f1, city: city, roomFormat: "Grand Large 70mm", times: ["18:00", "21:30"]),
                    CinemaShowtime(cinemaName: f2, city: city, roomFormat: "VOST Dolby Atmos", times: ["17:00", "20:15"])
                ],
                "1022789": [ // Del Revés 2
                    CinemaShowtime(cinemaName: f1, city: city, roomFormat: "VF 2D", times: ["15:00", "17:15", "19:30"])
                ]
            ]
        }
        
        // 6. JAPÓN
        if normalizedCode == "JP" || ["tokio", "tokyo", "osaka"].contains(normalizedCity) {
            let j1 = normalizedCity.contains("osaka") ? "TOHO Cinemas Umeda" : "TOHO Cinemas Shinjuku"
            let j2 = normalizedCity.contains("osaka") ? "Osaka Station City Cinema" : "109 Cinemas Premium Shinjuku"
            return [
                "508883": [ // El Chico y la Garza
                    CinemaShowtime(cinemaName: j1, city: city, roomFormat: "IMAX Laser 4K", times: ["16:00", "18:45", "21:30"]),
                    CinemaShowtime(cinemaName: j2, city: city, roomFormat: "Premium Sound Ryuichi Sakamoto", times: ["17:30", "20:15"])
                ],
                "940721": [ // Godzilla Minus One
                    CinemaShowtime(cinemaName: j1, city: city, roomFormat: "TCX Dolby Atmos", times: ["17:00", "19:40", "22:20"]),
                    CinemaShowtime(cinemaName: j2, city: city, roomFormat: "ScreenX 4DX", times: ["18:15", "21:00"])
                ],
                "533535": [ // Deadpool & Wolverine
                    CinemaShowtime(cinemaName: j2, city: city, roomFormat: "Sub 2D Atmos", times: ["18:00", "20:45"])
                ]
            ]
        }
        
        // 7. COLOMBIA
        if normalizedCode == "CO" || ["bogotá", "bogota", "medellín", "medellin", "cali"].contains(normalizedCity) {
            let cCol = normalizedCity.contains("medellin") ? "Cine Colombia Viva Envigado" :
                       normalizedCity.contains("cali") ? "Cine Colombia Chipichape" : "Cine Colombia Centro Mayor"
            let alt = normalizedCity.contains("medellin") ? "Colombo Americano" :
                      normalizedCity.contains("cali") ? "Cinemark Mallplaza Cali" : "Cinemateca de Bogotá"
            return [
                "693134": [
                    CinemaShowtime(cinemaName: cCol, city: city, roomFormat: "MegaSala IMAX", times: ["16:00", "19:30", "22:15"]),
                    CinemaShowtime(cinemaName: alt, city: city, roomFormat: "Sala de Cine", times: ["18:00", "21:00"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: cCol, city: city, roomFormat: "Dinamix 3D", times: ["15:00", "17:15", "19:30"])
                ],
                "533535": [
                    CinemaShowtime(cinemaName: cCol, city: city, roomFormat: "MegaSala Atmos", times: ["17:00", "20:00", "22:45"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: alt, city: city, roomFormat: "Sala Prime (Sub)", times: ["18:45", "21:30"])
                ]
            ]
        }
        
        // 8. CHILE
        if normalizedCode == "CL" || ["santiago", "valparaíso", "valparaiso", "concepción", "concepcion"].contains(normalizedCity) {
            return [
                "693134": [
                    CinemaShowtime(cinemaName: "Cine Hoyts Parque Arauco", city: city, roomFormat: "IMAX Laser", times: ["16:30", "20:00", "22:45"]),
                    CinemaShowtime(cinemaName: "Cineteca Nacional de Chile", city: city, roomFormat: "Sala de Cine", times: ["18:00", "20:45"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: "Cinemark Alto Las Condes", city: city, roomFormat: "XD 2D", times: ["15:00", "17:15", "19:30"])
                ],
                "533535": [
                    CinemaShowtime(cinemaName: "Cineplanet Costanera Center", city: city, roomFormat: "Sala Xtreme Atmos", times: ["17:30", "20:30", "23:00"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: "Cinemark Mallplaza Egaña", city: city, roomFormat: "IMAX 2D (Sub)", times: ["19:15", "22:00"])
                ]
            ]
        }
        
        // 9. PERÚ
        if normalizedCode == "PE" || ["lima", "arequipa", "cusco"].contains(normalizedCity) {
            return [
                "ekeko_pe_2026": [ // EKEKO - Película Peruana (Semana de Estreno)
                    CinemaShowtime(cinemaName: "Cineplanet Alcázar", city: city, roomFormat: "Sala 2D Digital", times: ["17:15", "19:45", "22:15"]),
                    CinemaShowtime(cinemaName: "Cinemark Jockey Plaza", city: city, roomFormat: "XD Dolby Atmos", times: ["18:00", "20:30", "23:00"]),
                    CinemaShowtime(cinemaName: "Cineplanet San Miguel", city: city, roomFormat: "Sala 2D", times: ["16:30", "19:00", "21:30"])
                ],
                "smile_2_2026": [ // Sonríe 2 - 2ª Semana en cines
                    CinemaShowtime(cinemaName: "Cinemark Jockey Plaza", city: city, roomFormat: "XD 2D", times: ["17:30", "20:15", "22:45"]),
                    CinemaShowtime(cinemaName: "Cineplanet Alcázar", city: city, roomFormat: "Prime 2D (Sub)", times: ["18:20", "21:10"])
                ],
                "693134": [
                    CinemaShowtime(cinemaName: "Cineplanet Alcázar", city: city, roomFormat: "Prime 2D (Sub)", times: ["16:40", "20:10"]),
                    CinemaShowtime(cinemaName: "Cinemark Jockey Plaza", city: city, roomFormat: "XD Dolby Atmos", times: ["17:00", "20:30", "23:15"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: "Cineplanet San Miguel", city: city, roomFormat: "2D Doblada", times: ["14:30", "16:45", "19:00"])
                ],
                "533535": [
                    CinemaShowtime(cinemaName: "Cinemark Jockey Plaza", city: city, roomFormat: "XD 3D", times: ["16:30", "19:30", "22:20"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: "Cineplanet Alcázar", city: city, roomFormat: "Prime (Sub)", times: ["18:50", "21:40"])
                ]
            ]
        }
        
        // 10. REINO UNIDO
        if normalizedCode == "GB" || normalizedCode == "UK" || ["londres", "london", "mánchester", "manchester"].contains(normalizedCity) {
            return [
                "693134": [
                    CinemaShowtime(cinemaName: "BFI IMAX Waterloo", city: city, roomFormat: "70mm IMAX", times: ["17:00", "20:30"]),
                    CinemaShowtime(cinemaName: "Odeon Luxe", city: city, roomFormat: "Dolby Cinema", times: ["18:15", "21:15"])
                ],
                "929590": [
                    CinemaShowtime(cinemaName: "Curzon Soho", city: city, roomFormat: "Screen 1 4K", times: ["17:30", "20:15"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: "Vue Printworks", city: city, roomFormat: "IMAX Laser", times: ["19:00", "21:45"])
                ]
            ]
        }
        
        // 11. ALEMANIA
        if normalizedCode == "DE" || ["berlín", "berlin", "múnich", "munich"].contains(normalizedCity) {
            return [
                "693134": [
                    CinemaShowtime(cinemaName: "Zoo Palast", city: city, roomFormat: "Dolby Atmos", times: ["17:30", "20:45"])
                ],
                "945961": [
                    CinemaShowtime(cinemaName: "CineStar Potsdamer Platz", city: city, roomFormat: "OV IMAX Laser", times: ["18:30", "21:15"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: "Zoo Palast", city: city, roomFormat: "Digital 2D", times: ["16:00", "18:15"])
                ]
            ]
        }
        
        // 12. ITALIA
        if normalizedCode == "IT" || ["roma", "rome", "milán", "milan"].contains(normalizedCity) {
            return [
                "693134": [
                    CinemaShowtime(cinemaName: "Cinema Barberini 4K", city: city, roomFormat: "Dolby Atmos", times: ["17:30", "20:45"])
                ],
                "937287": [
                    CinemaShowtime(cinemaName: "Cinema Anteo", city: city, roomFormat: "Sala President", times: ["18:15", "21:00"])
                ],
                "1022789": [
                    CinemaShowtime(cinemaName: "The Space Cinema Moderno", city: city, roomFormat: "Digital 2D", times: ["16:00", "18:30"])
                ]
            ]
        }
        
        // Fallback genérico inteligente para cualquier otra ubicación
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
    
    public func getShowtimes(forMovieId movieId: String, city: String) async throws -> [CinemaShowtime] {
        // 1. Intentar consultar en vivo la API REST conectada a Neon DB
        do {
            struct ShowtimesResponse: Codable {
                let showtimes: [CinemaShowtimeDTO]
            }
            let res: ShowtimesResponse = try await MovieSocialAPIClient.shared.sendRequest(
                endpoint: "movies/\(movieId)/showtimes",
                method: .get,
                queryParams: ["city": city]
            )
            if !res.showtimes.isEmpty {
                return res.showtimes.map { dto in
                    CinemaShowtime(
                        cinemaName: dto.cinemaName,
                        city: dto.city,
                        roomFormat: "\(dto.screenType) • \(dto.languageVersion)",
                        times: dto.parsedTimes
                    )
                }
            }
        } catch {
            // Fallback a catálogo curado offline
        }
        
        let cityMovies = try await getMoviesInTheaters(city: city, countryCode: "")
        return cityMovies[movieId] ?? []
    }
}
