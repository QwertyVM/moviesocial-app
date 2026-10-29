import SwiftUI

/// Tarjeta minimalista de película para listas y cuadrículas
public struct MoviePosterCard: View {
    public let movie: Movie
    public let friendsAverage: Double?
    public let onTap: () -> Void
    
    public init(movie: Movie, friendsAverage: Double? = nil, onTap: @escaping () -> Void) {
        self.movie = movie
        self.friendsAverage = friendsAverage
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Poster
                ZStack(alignment: .topTrailing) {
                    posterImage
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    
                    // Quick Rotten Tomatoes pill on top right
                    if let tomatometer = movie.ratings.rottenTomatoesCritics {
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
                        .padding(6)
                    }
                }
                
                // Title and year
                VStack(alignment: .leading, spacing: 2) {
                    Text(movie.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
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

