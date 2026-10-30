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
        HStack(spacing: isCompact ? 6 : 8) {
            // Score Cruce Ponderado (IMDb + RT)
            if let composite = ratings.formattedCompositeScore {
                badgeItem(
                    label: "SCORE",
                    value: composite,
                    accentColor: Theme.Colors.imdb
                )
            }
            
            // Rotten Tomatoes Tomatometer
            if let tomatometer = ratings.rottenTomatoesCritics {
                badgeItem(
                    label: "RT",
                    value: "\(tomatometer)%",
                    accentColor: Theme.Colors.rottenTomatoesCritics
                )
            }
            
            // Rotten Tomatoes Audience (Popcorn)
            if let audience = ratings.rottenTomatoesAudience {
                badgeItem(
                    label: "POPCORN",
                    value: "\(audience)%",
                    accentColor: Theme.Colors.rottenTomatoesAudience
                )
            }
            
            // IMDb Score
            if let imdb = ratings.imdbScore {
                badgeItem(
                    label: "IMDb",
                    value: String(format: "%.1f", imdb),
                    accentColor: Theme.Colors.imdb
                )
            }
            
            // Friends Average
            if let friendsAvg = friendsAverage, friendsCount > 0 {
                badgeItem(
                    label: "AMIGOS",
                    value: String(format: "%.1f", friendsAvg),
                    accentColor: Theme.Colors.friendsAccent
                )
            }
        }
    }
    
    @ViewBuilder
    private func badgeItem(
        label: String,
        value: String,
        accentColor: Color
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: isCompact ? 8 : 9, weight: .bold))
                .tracking(0.5)
                .foregroundColor(accentColor)
            
            Text(value)
                .font(.system(size: isCompact ? 10.5 : 12, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 3 : 5)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.Colors.border, lineWidth: 0.8)
        )
    }
}
