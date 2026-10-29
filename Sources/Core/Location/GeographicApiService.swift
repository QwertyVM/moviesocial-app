import Foundation
import CoreLocation

/// Representa un lugar geográfico con jerarquía completa: País -> Región/Estado -> Ciudad
public struct GeographicPlace: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let country: String
    public let countryCode: String
    public let region: String // Estado / Comunidad Autónoma / Provincia / Departamento
    public let city: String   // Ciudad / Municipio / Localidad
    public let flagEmoji: String
    public let latitude: Double?
    public let longitude: Double?
    
    public init(
        id: String = UUID().uuidString,
        country: String,
        countryCode: String,
        region: String,
        city: String,
        flagEmoji: String,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.country = country
        self.countryCode = countryCode
        self.region = region
        self.city = city
        self.flagEmoji = flagEmoji
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public var hierarchicalDescription: String {
        "\(country) › \(region) › \(city)"
    }
    
    public func toUserLocation(isDeviceLocation: Bool = false) -> UserLocation {
        UserLocation(
            city: city,
            country: country,
            countryCode: countryCode,
            flagEmoji: flagEmoji,
            isLocal: true,
            area: region,
            isDeviceLocation: isDeviceLocation
        )
    }
}

/// Región o estado dentro de una jerarquía de país
public struct HierarchicalRegion: Identifiable, Sendable, Codable, Hashable {
    public var id: String { name }
    public let name: String
    public let cities: [String]
    
    public init(name: String, cities: [String]) {
        self.name = name
        self.cities = cities
    }
}

/// País con su lista jerárquica de regiones y ciudades
public struct HierarchicalCountry: Identifiable, Sendable, Codable, Hashable {
    public var id: String { countryCode }
    public let name: String
    public let countryCode: String
    public let flagEmoji: String
    public let regions: [HierarchicalRegion]
    
    public init(name: String, countryCode: String, flagEmoji: String, regions: [HierarchicalRegion]) {
        self.name = name
        self.countryCode = countryCode
        self.flagEmoji = flagEmoji
        self.regions = regions
    }
}

/// Protocolo para el servicio de API geográfica
public protocol GeographicApiServiceProtocol: Sendable {
    func searchPlaces(query: String) async -> [GeographicPlace]
    func getCountries() -> [HierarchicalCountry]
    func getRegions(forCountryCode countryCode: String) -> [HierarchicalRegion]
    func getCities(forRegion regionName: String, inCountryCode countryCode: String) -> [String]
}

/// Servicio que se conecta a APIs geográficas y mantiene un dataset estructurado jerárquicamente
public final class GeographicApiService: GeographicApiServiceProtocol, @unchecked Sendable {
    public static let shared = GeographicApiService()
    
    private let urlSession: URLSession
    private let geocoder = CLGeocoder()
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // MARK: - Conexión a API Geográfica en Vivo (Open-Meteo Geocoding REST API)
    
    public func searchPlaces(query: String) async -> [GeographicPlace] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        
        // 1. Intentar consulta a la API Geográfica pública HTTPS (Open-Meteo Geocoding)
        if let apiResults = await fetchFromGeocodingAPI(query: trimmed), !apiResults.isEmpty {
            return apiResults
        }
        
        // 2. Fallback con CLGeocoder si está disponible
        if let clResults = await fetchFromCLGeocoder(query: trimmed), !clResults.isEmpty {
            return clResults
        }
        
        // 3. Fallback con base de datos jerárquica local estructurada
        return searchInLocalHierarchicalDatabase(query: trimmed)
    }
    
    private func fetchFromGeocodingAPI(query: String) async -> [GeographicPlace]? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=12&language=es&format=json") else {
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 3.5
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            let decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
            guard let results = decoded.results, !results.isEmpty else { return nil }
            
            return results.compactMap { item -> GeographicPlace? in
                guard let country = item.country, !country.isEmpty else { return nil }
                let countryCode = (item.country_code ?? "ES").uppercased()
                let flag = DeviceLocationService.shared.flagEmoji(forCountryCode: countryCode)
                let region = item.admin1 ?? item.admin2 ?? country
                let city = item.name
                
                return GeographicPlace(
                    id: "\(item.id)",
                    country: country,
                    countryCode: countryCode,
                    region: region,
                    city: city,
                    flagEmoji: flag,
                    latitude: item.latitude,
                    longitude: item.longitude
                )
            }
        } catch {
            return nil
        }
    }
    
    private func fetchFromCLGeocoder(query: String) async -> [GeographicPlace]? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            guard !placemarks.isEmpty else { return nil }
            
            return placemarks.prefix(6).compactMap { mark -> GeographicPlace? in
                guard let country = mark.country, let city = mark.locality ?? mark.subAdministrativeArea else {
                    return nil
                }
                let countryCode = mark.isoCountryCode?.uppercased() ?? "ES"
                let flag = DeviceLocationService.shared.flagEmoji(forCountryCode: countryCode)
                let region = mark.administrativeArea ?? mark.subAdministrativeArea ?? country
                
                return GeographicPlace(
                    id: "\(mark.location?.coordinate.latitude ?? 0)_\(mark.location?.coordinate.longitude ?? 0)",
                    country: country,
                    countryCode: countryCode,
                    region: region,
                    city: city,
                    flagEmoji: flag,
                    latitude: mark.location?.coordinate.latitude,
                    longitude: mark.location?.coordinate.longitude
                )
            }
        } catch {
            return nil
        }
    }
    
    private func searchInLocalHierarchicalDatabase(query: String) -> [GeographicPlace] {
        let q = query.lowercased()
        var matches: [GeographicPlace] = []
        
        for country in hierarchicalCatalog {
            for reg in country.regions {
                for city in reg.cities {
                    if city.lowercased().contains(q) || reg.name.lowercased().contains(q) || country.name.lowercased().contains(q) {
                        matches.append(
                            GeographicPlace(
                                id: "\(country.countryCode)_\(reg.name)_\(city)",
                                country: country.name,
                                countryCode: country.countryCode,
                                region: reg.name,
                                city: city,
                                flagEmoji: country.flagEmoji
                            )
                        )
                    }
                }
            }
        }
        return Array(matches.prefix(10))
    }
    
    // MARK: - Navegación Jerárquica Directa: País -> Región -> Ciudad
    
    public func getCountries() -> [HierarchicalCountry] {
        hierarchicalCatalog
    }
    
    public func getRegions(forCountryCode countryCode: String) -> [HierarchicalRegion] {
        guard let country = hierarchicalCatalog.first(where: { $0.countryCode.uppercased() == countryCode.uppercased() }) else {
            return []
        }
        return country.regions
    }
    
    public func getCities(forRegion regionName: String, inCountryCode countryCode: String) -> [String] {
        let regions = getRegions(forCountryCode: countryCode)
        guard let reg = regions.first(where: { $0.name.lowercased() == regionName.lowercased() }) else {
            return []
        }
        return reg.cities
    }
    
    // MARK: - Base de Datos Jerárquica Estructurada
    
    private let hierarchicalCatalog: [HierarchicalCountry] = [
        HierarchicalCountry(
            name: "España",
            countryCode: "ES",
            flagEmoji: "🇪🇸",
            regions: [
                HierarchicalRegion(name: "Comunidad de Madrid", cities: ["Madrid", "Alcalá de Henares", "Alcobendas", "Getafe", "Móstoles"]),
                HierarchicalRegion(name: "Cataluña", cities: ["Barcelona", "Badalona", "Sabadell", "Girona", "Tarragona", "Lleida"]),
                HierarchicalRegion(name: "Andalucía", cities: ["Sevilla", "Málaga", "Granada", "Córdoba", "Cádiz", "Marbella"]),
                HierarchicalRegion(name: "Comunidad Valenciana", cities: ["Valencia", "Alicante", "Elche", "Castellón"]),
                HierarchicalRegion(name: "País Vasco", cities: ["Bilbao", "San Sebastián", "Vitoria-Gasteiz"]),
                HierarchicalRegion(name: "Galicia", cities: ["A Coruña", "Vigo", "Santiago de Compostela"]),
                HierarchicalRegion(name: "Islas Baleares", cities: ["Palma de Mallorca", "Ibiza"])
            ]
        ),
        HierarchicalCountry(
            name: "México",
            countryCode: "MX",
            flagEmoji: "🇲🇽",
            regions: [
                HierarchicalRegion(name: "Ciudad de México", cities: ["Ciudad de México", "Coyoacán", "Cuauhtémoc", "Benito Juárez", "Polanco"]),
                HierarchicalRegion(name: "Jalisco", cities: ["Guadalajara", "Zapopan", "Tlaquepaque", "Puerto Vallarta"]),
                HierarchicalRegion(name: "Nuevo León", cities: ["Monterrey", "San Pedro Garza García", "San Nicolás de los Garza"]),
                HierarchicalRegion(name: "Quintana Roo", cities: ["Cancún", "Playa del Carmen", "Tulum", "Cozumel"]),
                HierarchicalRegion(name: "Puebla", cities: ["Puebla", "Cholula"]),
                HierarchicalRegion(name: "Yucatán", cities: ["Mérida", "Valladolid"]),
                HierarchicalRegion(name: "Guanajuato", cities: ["León", "Guanajuato", "San Miguel de Allende"])
            ]
        ),
        HierarchicalCountry(
            name: "Estados Unidos",
            countryCode: "US",
            flagEmoji: "🇺🇸",
            regions: [
                HierarchicalRegion(name: "California", cities: ["Los Ángeles", "San Francisco", "San Diego", "San José", "Santa Mónica"]),
                HierarchicalRegion(name: "New York", cities: ["Nueva York", "Brooklyn", "Queens", "Manhattan", "Buffalo"]),
                HierarchicalRegion(name: "Florida", cities: ["Miami", "Orlando", "Tampa", "Fort Lauderdale"]),
                HierarchicalRegion(name: "Illinois", cities: ["Chicago", "Naperville", "Evanston"]),
                HierarchicalRegion(name: "Texas", cities: ["Austin", "Houston", "Dallas", "San Antonio"]),
                HierarchicalRegion(name: "Washington", cities: ["Seattle", "Bellevue", "Tacoma"])
            ]
        ),
        HierarchicalCountry(
            name: "Argentina",
            countryCode: "AR",
            flagEmoji: "🇦🇷",
            regions: [
                HierarchicalRegion(name: "Buenos Aires", cities: ["Buenos Aires", "La Plata", "Mar del Plata", "Vicente López", "San Isidro"]),
                HierarchicalRegion(name: "Córdoba", cities: ["Córdoba", "Villa Carlos Paz", "Río Cuarto"]),
                HierarchicalRegion(name: "Santa Fe", cities: ["Rosario", "Santa Fe"]),
                HierarchicalRegion(name: "Mendoza", cities: ["Mendoza", "San Rafael", "Godoy Cruz"])
            ]
        ),
        HierarchicalCountry(
            name: "Colombia",
            countryCode: "CO",
            flagEmoji: "🇨🇴",
            regions: [
                HierarchicalRegion(name: "Bogotá D.C.", cities: ["Bogotá", "Chapinero", "Usaquén", "Suba"]),
                HierarchicalRegion(name: "Antioquia", cities: ["Medellín", "Envigado", "El Poblado", "Rionegro"]),
                HierarchicalRegion(name: "Valle del Cauca", cities: ["Cali", "Palmira", "Buga"]),
                HierarchicalRegion(name: "Atlántico", cities: ["Barranquilla", "Soledad"]),
                HierarchicalRegion(name: "Bolívar", cities: ["Cartagena"])
            ]
        ),
        HierarchicalCountry(
            name: "Chile",
            countryCode: "CL",
            flagEmoji: "🇨🇱",
            regions: [
                HierarchicalRegion(name: "Región Metropolitana", cities: ["Santiago", "Providencia", "Las Condes", "Vitacura"]),
                HierarchicalRegion(name: "Valparaíso", cities: ["Valparaíso", "Viña del Mar"]),
                HierarchicalRegion(name: "Biobío", cities: ["Concepción", "Talcahuano"])
            ]
        ),
        HierarchicalCountry(
            name: "Perú",
            countryCode: "PE",
            flagEmoji: "🇵🇪",
            regions: [
                HierarchicalRegion(name: "Lima", cities: ["Lima", "Miraflores", "San Isidro", "Barranco", "Surco"]),
                HierarchicalRegion(name: "Arequipa", cities: ["Arequipa"]),
                HierarchicalRegion(name: "Cusco", cities: ["Cusco", "Urubamba"])
            ]
        ),
        HierarchicalCountry(
            name: "Francia",
            countryCode: "FR",
            flagEmoji: "🇫🇷",
            regions: [
                HierarchicalRegion(name: "Île-de-France", cities: ["París", "Boulogne-Billancourt", "Saint-Denis", "Versailles"]),
                HierarchicalRegion(name: "Auvergne-Rhône-Alpes", cities: ["Lyon", "Grenoble", "Saint-Étienne"]),
                HierarchicalRegion(name: "Provence-Alpes-Côte d'Azur", cities: ["Marsella", "Niza", "Cannes", "Aix-en-Provence"])
            ]
        ),
        HierarchicalCountry(
            name: "Japón",
            countryCode: "JP",
            flagEmoji: "🇯🇵",
            regions: [
                HierarchicalRegion(name: "Tokio", cities: ["Tokio", "Shinjuku", "Shibuya", "Minato", "Ginza"]),
                HierarchicalRegion(name: "Osaka", cities: ["Osaka", "Umeda", "Namba"]),
                HierarchicalRegion(name: "Kioto", cities: ["Kioto", "Fushimi"])
            ]
        ),
        HierarchicalCountry(
            name: "Reino Unido",
            countryCode: "GB",
            flagEmoji: "🇬🇧",
            regions: [
                HierarchicalRegion(name: "Greater London", cities: ["Londres", "Westminster", "Camden", "Greenwich"]),
                HierarchicalRegion(name: "Greater Manchester", cities: ["Mánchester", "Salford"]),
                HierarchicalRegion(name: "West Midlands", cities: ["Birmingham", "Coventry"]),
                HierarchicalRegion(name: "Escocia", cities: ["Edimburgo", "Glasgow"])
            ]
        ),
        HierarchicalCountry(
            name: "Alemania",
            countryCode: "DE",
            flagEmoji: "🇩🇪",
            regions: [
                HierarchicalRegion(name: "Berlín", cities: ["Berlín", "Mitte", "Charlottenburg", "Kreuzberg"]),
                HierarchicalRegion(name: "Baviera", cities: ["Múnich", "Núremberg", "Augsburgo"]),
                HierarchicalRegion(name: "Hesse", cities: ["Fráncfort", "Wiesbaden"])
            ]
        ),
        HierarchicalCountry(
            name: "Italia",
            countryCode: "IT",
            flagEmoji: "🇮🇹",
            regions: [
                HierarchicalRegion(name: "Lacio", cities: ["Roma", "Tívoli"]),
                HierarchicalRegion(name: "Lombardía", cities: ["Milán", "Bérgamo", "Monza"]),
                HierarchicalRegion(name: "Véneto", cities: ["Venecia", "Verona", "Padua"])
            ]
        )
    ]
}

// MARK: - DTOs de Open-Meteo Geocoding API
private struct OpenMeteoGeocodingResponse: Codable {
    let results: [OpenMeteoGeocodingItem]?
}

private struct OpenMeteoGeocodingItem: Codable {
    let id: Int
    let name: String
    let latitude: Double?
    let longitude: Double?
    let country_code: String?
    let country: String?
    let admin1: String?
    let admin2: String?
}
