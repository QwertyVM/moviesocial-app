import SwiftUI

/// Tarjeta minimalista de película para listas y cuadrículas
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
                // Poster
                ZStack(alignment: .top) {
                    posterImage
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    
                    // Badges on top of poster
                    HStack {
                        // Match score pill on top left OR Theatrical Release badge (Estreno / 2ª Semana / En Cines)
                        if movie.isInTheatersLocally {
                            let status = movie.releaseStatus()
                            let isNational = movie.isNationalCinema(for: selectedCountryCode)
                            
                            HStack(spacing: 3) {
                                if isNational {
                                    Text(nationalFlag(for: movie.countryOfOrigin))
                                        .font(.system(size: 9))
                                } else if status == .premiereWeek {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 8))
                                } else {
                                    Image(systemName: "ticket.fill")
                                        .font(.system(size: 8))
                                }
                                
                                Text(status == .premiereWeek ? "ESTRENO" : (status == .secondWeek ? "2ª SEMANA" : "EN CINES"))
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(theatricalColor(status: status, isNational: isNational))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Capsule())
                        } else if let match = movie.matchScore {
                            HStack(spacing: 2) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8, weight: .bold))
                                Text("\(match)%")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(Theme.Colors.recommendationAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        // Cruce Ponderado (Score MovieSocial) o Tomatometer en la esquina derecha
                        if let composite = movie.ratings.formattedCompositeScore {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(Theme.Colors.imdb)
                                Text(composite)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.80))
                            .clipShape(Capsule())
                        } else if let tomatometer = movie.ratings.rottenTomatoesCritics {
                            HStack(spacing: 2) {
                                Text("🍅")
                                    .font(.system(size: 8))
                                Text("\(tomatometer)%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(6)
                }
                
                // Title and year
                VStack(alignment: .leading, spacing: 2) {
                    Text(movie.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    if let reason = movie.recommendationReason {
                        Text(reason)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.Colors.recommendationAccent)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        if let origin = movie.countryOfOrigin, movie.isNationalCinema(for: selectedCountryCode) {
                            Text(nationalFlag(for: origin))
                                .font(.system(size: 10))
                        }
                        
                        Text("\(movie.releaseYear)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        if let imdb = movie.ratings.imdbScore {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.textTertiary)
                            Text("★ \(String(format: "%.1f", imdb))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.Colors.imdb)
                        }
                        
                        if let friendsAvg = friendsAverage {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.textTertiary)
                            Text("👥 \(String(format: "%.1f", friendsAvg))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.Colors.friendsAccent)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
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
                    posterFallback
                @unknown default:
                    posterFallback
                }
            }
        } else {
            posterFallback
        }
    }
    
    private var posterFallback: some View {
        Rectangle()
            .fill(Theme.Colors.surfaceElevated)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "film")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text(movie.title)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            )
    }
}

