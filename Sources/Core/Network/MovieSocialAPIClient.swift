import Foundation

/// Métodos HTTP estándar para interactuar con la Base de Datos a través de la API REST
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Entorno de despliegue de la API REST
public enum APIEnvironment: Sendable, Equatable {
    case local
    case renderCloud(url: URL)
    
    public var baseURL: URL {
        switch self {
        case .local:
            return URL(string: "http://127.0.0.1:8080/api")!
        case .renderCloud(let url):
            return url
        }
    }
    
    public var displayName: String {
        switch self {
        case .local:
            return "Local (127.0.0.1:8080)"
        case .renderCloud:
            return "Render Cloud (Neon DB)"
        }
    }
}

/// Respuesta HTTP del servidor REST
public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let data: Data
    
    public init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

/// Error retornado por los servicios de red
public enum APIError: LocalizedError, Sendable {
    case invalidURL
    case serverError(statusCode: Int, message: String)
    case decodingError(String)
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de servicio inválida"
        case .serverError(let code, let msg):
            return "Error de servidor HTTP \(code): \(msg)"
        case .decodingError(let msg):
            return "Error decodificando respuesta: \(msg)"
        case .networkUnavailable:
            return "Servidor REST no disponible"
        }
    }
}

/// Cliente de Red para consumo de servicios REST conectados a la Base de Datos
public final class MovieSocialAPIClient: @unchecked Sendable {
    public static let shared = MovieSocialAPIClient()
    
    public var baseURL: URL
    public private(set) var environment: APIEnvironment
    private let session: URLSession
    
    private static let userDefaultsKey = "moviesocial_api_base_url"
    
    public init(
        environment: APIEnvironment = .local,
        session: URLSession = .shared
    ) {
        if let savedURLString = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let savedURL = URL(string: savedURLString) {
            self.environment = .renderCloud(url: savedURL)
            self.baseURL = savedURL
        } else {
            self.environment = environment
            self.baseURL = environment.baseURL
        }
        self.session = session
    }
    
    /// Cambia el entorno entre servidor local y Render Cloud (Neon DB)
    public func setEnvironment(_ newEnv: APIEnvironment) {
        self.environment = newEnv
        self.baseURL = newEnv.baseURL
        if case .renderCloud(let url) = newEnv {
            UserDefaults.standard.set(url.absoluteString, forKey: Self.userDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.userDefaultsKey)
        }
    }
    
    /// Permite asignar una URL directa de Render (ej. https://tu-app.onrender.com/api)
    public func setRenderURLString(_ urlString: String) -> Bool {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: clean), url.scheme == "https" || url.scheme == "http" else {
            return false
        }
        let finalURL = clean.hasSuffix("/api") ? url : url.appendingPathComponent("api")
        setEnvironment(.renderCloud(url: finalURL))
        return true
    }
    
    // MARK: - Ejecutor genérico de peticiones HTTP (GET, POST, PUT, DELETE)
    
    public func sendRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        queryParams: [String: String]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> T {
        let request = try buildURLRequest(endpoint: endpoint, method: method, queryParams: queryParams, body: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError(statusCode: 500, message: "Respuesta no es HTTP")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errMessage)
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error.localizedDescription)
            }
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.networkUnavailable
        }
    }
    
    // MARK: - Ejecutor sin decodificación (para DELETE / PUT / POST con status)
    
    @discardableResult
    public func execute(
        endpoint: String,
        method: HTTPMethod,
        queryParams: [String: String]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> HTTPResponse {
        let request = try buildURLRequest(endpoint: endpoint, method: method, queryParams: queryParams, body: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError(statusCode: 500, message: "Respuesta no es HTTP")
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let errMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errMessage)
            }
            return HTTPResponse(statusCode: httpResponse.statusCode, data: data)
        } catch let apiErr as APIError {
            throw apiErr
        } catch {
            throw APIError.networkUnavailable
        }
    }
    
    // MARK: - Health Check del Servidor
    
    public func checkServerHealth() async -> Bool {
        do {
            let resp = try await execute(endpoint: "/health", method: .get)
            return resp.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Helpers
    
    private func buildURLRequest(
        endpoint: String,
        method: HTTPMethod,
        queryParams: [String: String]?,
        body: (any Encodable)?
    ) throws -> URLRequest {
        let cleanEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        var url = baseURL.appendingPathComponent(cleanEndpoint)
        
        if let queryParams, !queryParams.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            if let builtURL = components?.url {
                url = builtURL
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8.0
        
        if let body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }
        
        return request
    }
}
