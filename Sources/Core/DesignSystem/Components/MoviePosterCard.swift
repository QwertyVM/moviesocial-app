import SwiftUI

/// Tarjeta minimalista y cinematográfica de película para cuadrícula del catálogo
public struct MoviePosterCard: View {
    public let movie: Movie
    public let friendsAverage: Double?
    public let selectedCountryCode: String?
    public let onTap: () -> Void
    
    public init(
        movie: Movie,
        friendsAverage: Double? = nil,
        selectedCountryCode: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.movie = movie
        self.friendsAverage = friendsAverage
        self.selectedCountryCode = selectedCountryCode
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 7) {
                // MARK: - Poster Image with Exact 2:3 Ratio
                ZStack(alignment: .top) {
                    posterImage
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            // Gradiente suave en la base del poster para contraste visual
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.35)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.border.opacity(0.7), lineWidth: 1)
                        )
                    
                    // MARK: - Badges superiores sobre el poster
                    HStack(alignment: .top) {
                        // Badge contextual izquierdo (Estreno / 2ª Semana / Cine Nacional / Match %)
                        if movie.isInTheatersLocally {
                            let status = movie.releaseStatus()
                            let isNational = movie.isNationalCinema(for: selectedCountryCode)
                            
                            HStack(spacing: 3.5) {
                                if isNational {
                                    Text(nationalFlag(for: movie.countryOfOrigin))
                                        .font(.system(size: 9))
                                } else if status == .premiereWeek {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 8, weight: .bold))
                                } else {
                                    Image(systemName: "ticket.fill")
                                        .font(.system(size: 8))
                                }
                                
                                Text(badgeLabel(status: status, isNational: isNational))
                                    .font(.system(size: 8.5, weight: .heavy))
                                    .tracking(0.5)
                            }
                            .foregroundColor(theatricalColor(status: status, isNational: isNational))
                            .padding(.horizontal, 6.5)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.82))
                                    .overlay(
                                        Capsule().stroke(theatricalColor(status: status, isNational: isNational).opacity(0.4), lineWidth: 0.8)
                                    )
                            )
                        } else if let match = movie.matchScore {
                            HStack(spacing: 2.5) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8, weight: .bold))
                                Text("\(match)%")
                                    .font(.system(size: 9.5, weight: .heavy))
                            }
                            .foregroundColor(Theme.Colors.recommendationAccent)
                            .padding(.horizontal, 6.5)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.82))
                                    .overlay(
                                        Capsule().stroke(Theme.Colors.recommendationAccent.opacity(0.4), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        Spacer()
                        
                        // Badge derecho: Cruce Ponderado Blended o Tomatometer
                        if let composite = movie.ratings.formattedCompositeScore {
                            HStack(spacing: 2.5) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.Colors.imdb)
                                Text(composite)
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.82))
                                    .overlay(
                                        Capsule().stroke(Theme.Colors.imdb.opacity(0.35), lineWidth: 0.8)
                                    )
                            )
                        } else if let tomatometer = movie.ratings.rottenTomatoesCritics {
                            HStack(spacing: 2.5) {
                                Text("🍅")
                                    .font(.system(size: 8))
                                Text("\(tomatometer)%")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.82))
                                    .overlay(
                                        Capsule().stroke(Color.red.opacity(0.35), lineWidth: 0.8)
                                    )
                            )
                        }
                    }
                    .padding(6.5)
                }
                
                // MARK: - Metadatos de la película
                VStack(alignment: .leading, spacing: 3) {
                    // Título principal con tipografía clara y elegante
                    Text(movie.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    // Razón personalizada si aplica (recomendaciones)
                    if let reason = movie.recommendationReason {
                        Text(reason)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.Colors.recommendationAccent)
                            .lineLimit(1)
                    }
                    
                    // Fila de información: Año, Bandera y Ratings
                    HStack(spacing: 4) {
                        if let origin = movie.countryOfOrigin, movie.isNationalCinema(for: selectedCountryCode) {
                            Text(nationalFlag(for: origin))
                                .font(.system(size: 10))
                        }
                        
                        Text("\(movie.releaseYear)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        if let imdb = movie.ratings.imdbScore {
                            Text("•")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.Colors.textTertiary)
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(Theme.Colors.imdb)
                                Text(String(format: "%.1f", imdb))
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                        
                        if let friendsAvg = friendsAverage {
                            Text("•")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.Colors.textTertiary)
                            HStack(spacing: 2) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(Theme.Colors.friendsAccent)
                                Text(String(format: "%.1f", friendsAvg))
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundColor(Theme.Colors.friendsAccent)
                            }
                        }
                    }
                    
                    // Mini indicador de salas activas si está en cines
                    if movie.isInTheatersLocally {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 4.5, height: 4.5)
                            Text(theatersSummary(for: movie))
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(Color.green.opacity(0.9))
                                .lineLimit(1)
                        }
                        .padding(.top, 1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func theatersSummary(for movie: Movie) -> String {
        if !movie.theatersPlaying.isEmpty {
            return movie.theatersPlaying.prefix(2).joined(separator: ", ")
        }
        return "En cines hoy"
    }
    
    private func badgeLabel(status: TheatricalReleaseStatus, isNational: Bool) -> String {
        if isNational {
            return "CINE LOCAL"
        }
        switch status {
        case .premiereWeek:
            return "ESTRENO"
        case .secondWeek:
            return "2ª SEMANA"
        case .inTheaters:
            return "EN CINES"
        case .comingSoon:
            return "PRÓXIMO"
        case .catalog:
            return "CATÁLOGO"
        }
    }
    
    private func theatricalColor(status: TheatricalReleaseStatus, isNational: Bool) -> Color {
        if isNational {
            return Color(red: 1.0, green: 0.35, blue: 0.35)
        }
        switch status {
        case .premiereWeek:
            return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .secondWeek:
            return Color(red: 0.3, green: 0.8, blue: 1.0)
        case .inTheaters:
            return Color.green
        case .comingSoon:
            return Color.purple
        case .catalog:
            return Theme.Colors.textSecondary
        }
    }
    
    private func nationalFlag(for code: String?) -> String {
        switch code?.uppercased() {
        case "PE": return "🇵🇪"
        case "ES": return "🇪🇸"
        case "MX": return "🇲🇽"
        case "AR": return "🇦🇷"
        case "FR": return "🇫🇷"
        case "JP": return "🇯🇵"
        case "CO": return "🇨🇴"
        case "CL": return "🇨🇱"
        case "US": return "🇺🇸"
        default: return "🎬"
        }
    }
    
    @ViewBuilder
    private var posterImage: some View {
        if let posterURL = movie.posterURL {
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Theme.Colors.surfaceElevated)
                        .overlay(
                            ProgressView()
                                .tint(Theme.Colors.textSecondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                case .failure:
                    posterPlaceholder
                @unknown default:
                    posterPlaceholder
                }
            }
        } else {
            posterPlaceholder
        }
    }
    
    private var posterPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Theme.Colors.surfaceElevated)
            VStack(spacing: 8) {
                Image(systemName: "film")
                    .font(.system(size: 26))
                    .foregroundColor(Theme.Colors.textTertiary)
                Text(movie.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
        }
    }
}
