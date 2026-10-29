import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Intelligent Location & Regional Billboard Tests")
struct LocationAndBillboardTests {
    
    // MARK: - Device Location Service Tests
    
    @Test("DeviceLocationService detects location reliably without hanging")
    func testDeviceLocationDetection() async {
        let service = DeviceLocationService.shared
        let location = await service.detectDeviceLocation()
        
        #expect(!location.city.isEmpty)
        #expect(!location.country.isEmpty)
        #expect(!location.countryCode.isEmpty)
        #expect(!location.flagEmoji.isEmpty)
        #expect(location.isDeviceLocation == true)
        #expect(location.area != nil)
    }
    
    // MARK: - Country Groups & Area Tests
    
    @Test("Showtimes service provides structured CountryAreaGroups")
    func testCountryAreaGroups() {
        let service = ShowtimesServiceImpl()
        let groups = service.getAvailableCountryGroups()
        
        #expect(groups.count >= 10)
        let countryCodes = groups.map(\.countryCode)
        #expect(countryCodes.contains("ES"))
        #expect(countryCodes.contains("MX"))
        #expect(countryCodes.contains("US"))
        #expect(countryCodes.contains("AR"))
        #expect(countryCodes.contains("CO"))
        #expect(countryCodes.contains("JP"))
        #expect(countryCodes.contains("FR"))
        
        // Granularidad de áreas en España
        let spain = groups.first(where: { $0.countryCode == "ES" })
        #expect(spain != nil)
        let spainCities = spain?.areas.map(\.city) ?? []
        #expect(spainCities.contains("Madrid"))
        #expect(spainCities.contains("Barcelona"))
        #expect(spainCities.contains("Valencia"))
        #expect(spainCities.contains("Sevilla"))
        
        // Granularidad de áreas en México
        let mexico = groups.first(where: { $0.countryCode == "MX" })
        #expect(mexico != nil)
        let mexicoCities = mexico?.areas.map(\.city) ?? []
        #expect(mexicoCities.contains("Ciudad de México"))
        #expect(mexicoCities.contains("Guadalajara"))
        #expect(mexicoCities.contains("Monterrey"))
    }
    
    // MARK: - Regional Billboard Variations
    
    @Test("Billboards vary significantly across different countries and cities")
    func testRegionalBillboardVariations() async throws {
        let repository = MovieRepositoryImpl()
        
        // 1. Cartelera en Madrid (España)
        let madridMovies = try await repository.getNowPlaying(city: "Madrid", countryCode: "ES", page: 1)
        let madridInTheaters = madridMovies.filter(\.isInTheatersLocally)
        #expect(!madridInTheaters.isEmpty)
        #expect(madridInTheaters.contains(where: { $0.title.contains("Sociedad de la Nieve") }))
        let madridTheaters = madridInTheaters.flatMap(\.theatersPlaying)
        #expect(madridTheaters.contains(where: { $0.contains("Kinépolis") || $0.contains("Yelmo") || $0.contains("Cinesa") }))
        
        // 2. Cartelera en Ciudad de México (México)
        let cdmxMovies = try await repository.getNowPlaying(city: "Ciudad de México", countryCode: "MX", page: 1)
        let cdmxInTheaters = cdmxMovies.filter(\.isInTheatersLocally)
        #expect(!cdmxInTheaters.isEmpty)
        #expect(cdmxInTheaters.contains(where: { $0.title.contains("Radical") }))
        let cdmxTheaters = cdmxInTheaters.flatMap(\.theatersPlaying)
        #expect(cdmxTheaters.contains(where: { $0.contains("Cinépolis") || $0.contains("Cinemex") || $0.contains("Cineteca") }))
        
        // 3. Cartelera en Los Ángeles / New York (USA)
        let usaMovies = try await repository.getNowPlaying(city: "Los Ángeles", countryCode: "US", page: 1)
        let usaInTheaters = usaMovies.filter(\.isInTheatersLocally)
        #expect(!usaInTheaters.isEmpty)
        #expect(usaInTheaters.contains(where: { $0.title.contains("Civil War") || $0.title.contains("Challengers") }))
        let usaTheaters = usaInTheaters.flatMap(\.theatersPlaying)
        #expect(usaTheaters.contains(where: { $0.contains("AMC") || $0.contains("TCL Chinese") || $0.contains("Alamo") }))
        
        // 4. Cartelera en Tokio (Japón)
        let tokyoMovies = try await repository.getNowPlaying(city: "Tokio", countryCode: "JP", page: 1)
        let tokyoInTheaters = tokyoMovies.filter(\.isInTheatersLocally)
        #expect(!tokyoInTheaters.isEmpty)
        #expect(tokyoInTheaters.contains(where: { $0.title.contains("Garza") || $0.title.contains("Godzilla") }))
        let tokyoTheaters = tokyoInTheaters.flatMap(\.theatersPlaying)
        #expect(tokyoTheaters.contains(where: { $0.contains("TOHO") || $0.contains("109") || $0.contains("Shinjuku") }))
        
        // 5. Cartelera en París (Francia)
        let parisMovies = try await repository.getNowPlaying(city: "París", countryCode: "FR", page: 1)
        let parisInTheaters = parisMovies.filter(\.isInTheatersLocally)
        #expect(!parisInTheaters.isEmpty)
        #expect(parisInTheaters.contains(where: { $0.title.contains("Anatomía de una Caída") }))
        let parisTheaters = parisInTheaters.flatMap(\.theatersPlaying)
        #expect(parisTheaters.contains(where: { $0.contains("MK2") || $0.contains("Grand Rex") || $0.contains("Pathé") }))
    }
    
    // MARK: - MovieCatalogViewModel Tests
    
    @Test("MovieCatalogViewModel switches to device location via useDeviceLocation()")
    @MainActor
    func testViewModelUseDeviceLocation() async {
        let repo = MovieRepositoryImpl()
        let env = AppEnvironment(movieRepository: repo)
        let vm = env.makeMovieCatalogViewModel()
        
        await vm.loadCatalog()
        #expect(vm.selectedCity.isDeviceLocation == false)
        
        await vm.useDeviceLocation()
        #expect(vm.selectedCity.isDeviceLocation == true)
        #expect(!vm.nowPlayingMovies.isEmpty)
    }
    
    @Test("AreaLocation converts smoothly to UserLocation")
    func testAreaLocationToUserLocation() {
        let area = AreaLocation(
            city: "Barcelona",
            area: "Cataluña",
            country: "España",
            countryCode: "ES",
            flagEmoji: "🇪🇸",
            prominentTheaters: ["Phenomena", "Cinesa Diagonal"]
        )
        
        let userLoc = area.toUserLocation
        #expect(userLoc.city == "Barcelona")
        #expect(userLoc.area == "Cataluña")
        #expect(userLoc.countryCode == "ES")
        #expect(userLoc.detailedFormattedText == "🇪🇸 Barcelona (Cataluña), España")
        #expect(userLoc.shortLabel == "🇪🇸 Barcelona")
        #expect(userLoc.hierarchicalFormattedText == "🇪🇸 España › Cataluña › Barcelona")
    }
    
    // MARK: - UserLocation Serialization & Compatibility Tests
    
    @Test("UserLocation decodes legacy JSON payloads without area or isDeviceLocation")
    func testLegacyUserLocationDecoding() throws {
        let legacyJson = """
        {
            "city": "Sevilla",
            "country": "España",
            "countryCode": "ES",
            "flagEmoji": "🇪🇸",
            "isLocal": true
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(UserLocation.self, from: legacyJson)
        #expect(decoded.city == "Sevilla")
        #expect(decoded.country == "España")
        #expect(decoded.area == nil)
        #expect(decoded.isDeviceLocation == false)
        #expect(decoded.formattedText == "🇪🇸 Sevilla, España")
        #expect(decoded.hierarchicalFormattedText == "🇪🇸 España › Sevilla")
    }
    
    @Test("UserLocation encodes and decodes area and isDeviceLocation")
    func testUserLocationRoundtripWithNewFields() throws {
        let location = UserLocation(
            city: "Cancún",
            country: "México",
            countryCode: "MX",
            flagEmoji: "🇲🇽",
            isLocal: true,
            area: "Riviera Maya",
            isDeviceLocation: true
        )
        
        let data = try JSONEncoder().encode(location)
        let decoded = try JSONDecoder().decode(UserLocation.self, from: data)
        
        #expect(decoded.city == "Cancún")
        #expect(decoded.country == "México")
        #expect(decoded.area == "Riviera Maya")
        #expect(decoded.isDeviceLocation == true)
        #expect(decoded.detailedFormattedText == "🇲🇽 Cancún (Riviera Maya), México")
        #expect(decoded.hierarchicalFormattedText == "🇲🇽 México › Riviera Maya › Cancún")
    }
    
    // MARK: - GeographicApiService & Hierarchy Tests
    
    @Test("GeographicApiService provides hierarchical countries, regions and cities")
    func testGeographicApiServiceHierarchy() {
        let service = GeographicApiService.shared
        let countries = service.getCountries()
        
        #expect(countries.count >= 12)
        let countryCodes = countries.map(\.countryCode)
        #expect(countryCodes.contains("ES"))
        #expect(countryCodes.contains("MX"))
        #expect(countryCodes.contains("US"))
        #expect(countryCodes.contains("AR"))
        #expect(countryCodes.contains("FR"))
        #expect(countryCodes.contains("JP"))
        
        // Verificación de regiones de España
        let spainRegions = service.getRegions(forCountryCode: "ES")
        #expect(!spainRegions.isEmpty)
        let regionNames = spainRegions.map(\.name)
        #expect(regionNames.contains("Comunidad de Madrid"))
        #expect(regionNames.contains("Cataluña"))
        #expect(regionNames.contains("Andalucía"))
        
        // Verificación de ciudades dentro de Cataluña
        let cataloniaCities = service.getCities(forRegion: "Cataluña", inCountryCode: "ES")
        #expect(cataloniaCities.contains("Barcelona"))
        #expect(cataloniaCities.contains("Badalona") || cataloniaCities.contains("Girona"))
    }
    
    @Test("GeographicApiService searches places and converts to UserLocation")
    func testGeographicApiServiceSearch() async {
        let service = GeographicApiService.shared
        
        // Búsqueda en catálogo interno / fallback
        let results = await service.searchPlaces(query: "Valencia")
        #expect(!results.isEmpty)
        
        let place = results.first!
        #expect(place.city.contains("Valencia") || place.region.contains("Valencia"))
        #expect(place.country.contains("España") || !place.country.isEmpty)
        #expect(!place.flagEmoji.isEmpty)
        #expect(!place.hierarchicalDescription.isEmpty)
        
        let userLocation = place.toUserLocation()
        #expect(!userLocation.city.isEmpty)
        #expect(!userLocation.country.isEmpty)
        #expect(userLocation.area != nil)
    }
}
