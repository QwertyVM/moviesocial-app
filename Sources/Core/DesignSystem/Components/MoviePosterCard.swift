import SwiftUI

/// Tarjeta minimalista de película para catálogo y cuadrículas cinephile
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
            VStack(alignment: .leading, spacing: 6) {
                // MARK: - Poster Image with Exact 2:3 Ratio (Conservando tamaño exacto)
                ZStack(alignment: .top) {
                    posterImage
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.Colors.border, lineWidth: 0.8)
                        )
                    
                    // MARK: - Badges sutiles y minimalistas sobre el póster
                    HStack(alignment: .top) {
                        // Badge izquierdo: Estado en cines o afinidad
                        if movie.isInTheatersLocally {
                            let status = movie.releaseStatus()
                            let isNational = movie.isNationalCinema(for: selectedCountryCode)
                            
                            HStack(spacing: 3) {
                                if isNational {
                                    Text(nationalFlag(for: movie.countryOfOrigin))
                                        .font(.system(size: 8.5))
                                } else if status == .premiereWeek {
                                    Circle()
                                        .fill(Color(red: 255/255, green: 190/255, blue: 40/255))
                                        .frame(width: 4, height: 4)
                                }
                                
                                Text(badgeLabel(status: status, isNational: isNational))
                                    .font(.system(size: 8.5, weight: .semibold))
                                    .tracking(0.3)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                        } else if let match = movie.matchScore {
                            HStack(spacing: 2) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 7, weight: .bold))
                                Text("\(match)%")
                                    .font(.system(size: 8.5, weight: .bold))
                            }
                            .foregroundColor(Theme.Colors.recommendationAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Theme.Colors.recommendationAccent.opacity(0.25), lineWidth: 0.5)
                            )
                        }
                        
                        Spacer()
                        
                        // Badge derecho: Calificación consolidada
                        if let composite = movie.ratings.formattedCompositeScore {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 7.5))
                                    .foregroundColor(Theme.Colors.imdb)
                                Text(composite)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                        } else if let tomatometer = movie.ratings.rottenTomatoesCritics {
                            HStack(spacing: 2) {
                                Text("🍅")
                                    .font(.system(size: 7.5))
                                Text("\(tomatometer)%")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(5)
                }
                
                // MARK: - Metadatos minimalistas de la película
                VStack(alignment: .leading, spacing: 2.5) {
                    Text(movie.title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("\(movie.releaseYear)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        if let imdb = movie.ratings.imdbScore {
                            Text("•")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.Colors.textTertiary)
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 7))
                                    .foregroundColor(Theme.Colors.imdb)
                                Text(String(format: "%.1f", imdb))
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                        
                        if let friendsAvg = friendsAverage {
                            Text("•")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.Colors.textTertiary)
                            HStack(spacing: 2) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 7))
                                    .foregroundColor(Theme.Colors.friendsAccent)
                                Text(String(format: "%.1f", friendsAvg))
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(Theme.Colors.friendsAccent)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func badgeLabel(status: TheatricalReleaseStatus, isNational: Bool) -> String {
        if isNational {
            return "Cine Local"
        }
        switch status {
        case .premiereWeek:
            return "Estreno"
        case .secondWeek:
            return "2ª Semana"
        case .inTheaters:
            return "En Cines"
        case .comingSoon:
            return "Próximo"
        case .catalog:
            return "Catálogo"
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
                                .tint(Theme.Colors.textTertiary)
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
            VStack(spacing: 6) {
                Image(systemName: "film")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(Theme.Colors.textTertiary)
                Text(movie.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
        }
    }
}
