import SwiftUI

/// Componente minimalista para desplegar los ratings de Rotten Tomatoes, IMDb y Amigos
public struct RatingBadgesView: View {
    public let ratings: ExternalRatings
    public let friendsAverage: Double?
    public let friendsCount: Int
    public let isCompact: Bool
    
    public init(
        ratings: ExternalRatings,
        friendsAverage: Double? = nil,
        friendsCount: Int = 0,
        isCompact: Bool = false
    ) {
        self.ratings = ratings
        self.friendsAverage = friendsAverage
        self.friendsCount = friendsCount
        self.isCompact = isCompact
    }
    
    public var body: some View {
        HStack(spacing: isCompact ? 8 : 14) {
            // Score Cruce Ponderado (IMDb + RT)
            if let composite = ratings.formattedCompositeScore {
                badgeItem(
                    icon: "✨",
                    value: composite,
                    label: isCompact ? nil : "MovieScore",
                    accentColor: Theme.Colors.recommendationAccent
                )
            }
            
            // Rotten Tomatoes Tomatometer (Críticos)
            if let tomatometer = ratings.rottenTomatoesCritics {
                badgeItem(
                    icon: "🍅",
                    value: "\(tomatometer)%",
                    label: isCompact ? nil : "Tomatometer",
                    accentColor: Theme.Colors.rottenTomatoesCritics
                )
            }
            
            // Rotten Tomatoes Audience (Popcorn)
            if let audience = ratings.rottenTomatoesAudience {
                badgeItem(
                    icon: "🍿",
                    value: "\(audience)%",
                    label: isCompact ? nil : "Audiencia",
                    accentColor: Theme.Colors.rottenTomatoesAudience
                )
            }
            
            // IMDb Score
            if let imdb = ratings.imdbScore {
                badgeItem(
                    icon: "★",
                    value: String(format: "%.1f", imdb),
                    label: isCompact ? nil : "IMDb",
                    accentColor: Theme.Colors.imdb
                )
            }
            
            // Friends Average (si existen reseñas de amigos)
            if let friendsAvg = friendsAverage, friendsCount > 0 {
                badgeItem(
                    icon: "👥",
                    value: String(format: "%.1f", friendsAvg),
                    label: isCompact ? nil : "Amigos (\(friendsCount))",
                    accentColor: Theme.Colors.friendsAccent
                )
            }
        }
    }
    
    @ViewBuilder
    private func badgeItem(
        icon: String,
        value: String,
        label: String?,
        accentColor: Color
    ) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(isCompact ? .caption2 : .caption)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(isCompact ? .caption.bold() : .subheadline.bold())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if let label {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 3 : 5)
        .background(Theme.Colors.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.small)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
    }
}

