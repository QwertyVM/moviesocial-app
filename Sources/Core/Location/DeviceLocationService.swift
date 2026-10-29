import Foundation
import CoreLocation

/// Servicio inteligente de detección y resolución de ubicación del dispositivo (GPS / Región)
public final class DeviceLocationService: NSObject, @unchecked Sendable, CLLocationManagerDelegate {
    public static let shared = DeviceLocationService()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private let lock = NSLock()
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    /// Detecta de forma inteligente la ubicación del dispositivo mediante GPS o región del sistema
    public func detectDeviceLocation() async -> UserLocation {
        // 1. Intentar obtener coordenadas del hardware mediante GPS si están disponibles
        if let location = await requestHardwareLocation() {
            if let resolved = await reverseGeocode(location: location) {
                return resolved
            }
        }
        
        // 2. Fallback inteligente instantáneo: Región y Zona Horaria del sistema
        return inferLocationFromSystemEnvironment()
    }
    
    private func requestHardwareLocation() async -> CLLocation? {
        let currentStatus = locationManager.authorizationStatus
        
        if currentStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Breve espera para respuesta de permisos
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
        
        let updatedStatus = locationManager.authorizationStatus
        guard updatedStatus == .authorizedWhenInUse || updatedStatus == .authorizedAlways else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            lock.lock()
            self.locationContinuation = continuation
            lock.unlock()
            
            #if os(iOS)
            locationManager.requestLocation()
            #else
            locationManager.startUpdatingLocation()
            #endif
            
            // Timeout de seguridad de 1.8s para garantizar máxima fluidez
            Task {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                self.cancelOnTimeout()
            }
        }
    }
    
    private func cancelOnTimeout() {
        lock.lock()
        defer { lock.unlock() }
        if let cont = locationContinuation {
            locationContinuation = nil
            #if os(macOS)
            locationManager.stopUpdatingLocation()
            #endif
            cont.resume(returning: locationManager.location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        #if os(macOS)
        locationManager.stopUpdatingLocation()
        #endif
        lock.lock()
        if let cont = locationContinuation {
            locationContinuation = nil
            lock.unlock()
            cont.resume(returning: locations.last)
        } else {
            lock.unlock()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if os(macOS)
        locationManager.stopUpdatingLocation()
        #endif
        lock.lock()
        if let cont = locationContinuation {
            locationContinuation = nil
            lock.unlock()
            cont.resume(returning: nil)
        } else {
            lock.unlock()
        }
    }
    
    private func reverseGeocode(location: CLLocation) async -> UserLocation? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let mark = placemarks.first else { return nil }
            
            let city = mark.locality ?? mark.subAdministrativeArea ?? "Madrid"
            let country = mark.country ?? "España"
            let countryCode = mark.isoCountryCode?.uppercased() ?? "ES"
            let flag = flagEmoji(forCountryCode: countryCode)
            let area = mark.administrativeArea ?? city
            
            return UserLocation(
                city: city,
                country: country,
                countryCode: countryCode,
                flagEmoji: flag,
                isLocal: true,
                area: area,
                isDeviceLocation: true
            )
        } catch {
            return nil
        }
    }
    
    /// Deduce de forma inteligente la ubicación basada en la configuración regional del sistema del usuario
    public func inferLocationFromSystemEnvironment() -> UserLocation {
        let regionCode = Locale.current.region?.identifier.uppercased() ?? "ES"
        let timeZoneId = TimeZone.current.identifier
        
        return locationForRegionAndZone(regionCode: regionCode, timeZoneId: timeZoneId)
    }
    
    public func locationForRegionAndZone(regionCode: String, timeZoneId: String) -> UserLocation {
        switch regionCode {
        case "MX":
            return UserLocation(
                city: "Ciudad de México",
                country: "México",
                countryCode: "MX",
                flagEmoji: "🇲🇽",
                isLocal: true,
                area: "CDMX / Valle de México",
                isDeviceLocation: true
            )
        case "US":
            if timeZoneId.contains("New_York") || timeZoneId.contains("Eastern") {
                return UserLocation(
                    city: "Nueva York",
                    country: "Estados Unidos",
                    countryCode: "US",
                    flagEmoji: "🇺🇸",
                    isLocal: true,
                    area: "New York",
                    isDeviceLocation: true
                )
            } else {
                return UserLocation(
                    city: "Los Ángeles",
                    country: "Estados Unidos",
                    countryCode: "US",
                    flagEmoji: "🇺🇸",
                    isLocal: true,
                    area: "California",
                    isDeviceLocation: true
                )
            }
        case "AR":
            return UserLocation(
                city: "Buenos Aires",
                country: "Argentina",
                countryCode: "AR",
                flagEmoji: "🇦🇷",
                isLocal: true,
                area: "CABA",
                isDeviceLocation: true
            )
        case "CO":
            return UserLocation(
                city: "Bogotá",
                country: "Colombia",
                countryCode: "CO",
                flagEmoji: "🇨🇴",
                isLocal: true,
                area: "Bogotá D.C.",
                isDeviceLocation: true
            )
        case "CL":
            return UserLocation(
                city: "Santiago",
                country: "Chile",
                countryCode: "CL",
                flagEmoji: "🇨🇱",
                isLocal: true,
                area: "Región Metropolitana",
                isDeviceLocation: true
            )
        case "PE":
            return UserLocation(
                city: "Lima",
                country: "Perú",
                countryCode: "PE",
                flagEmoji: "🇵🇪",
                isLocal: true,
                area: "Lima Metropolitana",
                isDeviceLocation: true
            )
        case "FR":
            return UserLocation(
                city: "París",
                country: "Francia",
                countryCode: "FR",
                flagEmoji: "🇫🇷",
                isLocal: true,
                area: "Île-de-France",
                isDeviceLocation: true
            )
        case "GB", "UK":
            return UserLocation(
                city: "Londres",
                country: "Reino Unido",
                countryCode: "GB",
                flagEmoji: "🇬🇧",
                isLocal: true,
                area: "Greater London",
                isDeviceLocation: true
            )
        case "JP":
            return UserLocation(
                city: "Tokio",
                country: "Japón",
                countryCode: "JP",
                flagEmoji: "🇯🇵",
                isLocal: true,
                area: "Kanto",
                isDeviceLocation: true
            )
        case "DE":
            return UserLocation(
                city: "Berlín",
                country: "Alemania",
                countryCode: "DE",
                flagEmoji: "🇩🇪",
                isLocal: true,
                area: "Berlín",
                isDeviceLocation: true
            )
        case "IT":
            return UserLocation(
                city: "Roma",
                country: "Italia",
                countryCode: "IT",
                flagEmoji: "🇮🇹",
                isLocal: true,
                area: "Lacio",
                isDeviceLocation: true
            )
        case "ES":
            fallthrough
        default:
            return UserLocation(
                city: "Madrid",
                country: "España",
                countryCode: "ES",
                flagEmoji: "🇪🇸",
                isLocal: true,
                area: "Comunidad de Madrid",
                isDeviceLocation: true
            )
        }
    }
    
    public func flagEmoji(forCountryCode code: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for scalar in code.uppercased().unicodeScalars {
            if let val = UnicodeScalar(base + scalar.value) {
                s.unicodeScalars.append(val)
            }
        }
        return s.isEmpty ? "🌐" : s
    }
}
