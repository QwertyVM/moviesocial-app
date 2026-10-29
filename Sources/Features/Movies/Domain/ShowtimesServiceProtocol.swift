import Foundation

/// Servicio de consulta de cartelera física y salas de proyección por ciudad
public protocol ShowtimesServiceProtocol: Sendable {
    /// Obtiene las salas y horarios para una película específica en una ciudad dada
    func getShowtimes(forMovieId movieId: String, city: String) async throws -> [CinemaShowtime]
    
    /// Obtiene el mapa de películas actualmente en cartelera en una ciudad dada: [movieId: [CinemaShowtime]]
    func getMoviesInTheaters(city: String, countryCode: String) async throws -> [String: [CinemaShowtime]]
    
    /// Lista de ciudades soportadas con información de país y bandera
    func getAvailableCities() -> [UserLocation]
}
