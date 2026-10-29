import SwiftUI

/// Selector minimalista de puntuación personal (escala 1 a 5 con incrementos de 0.5)
public struct MinimalistRatingPicker: View {
    @Binding public var rating: Double
    public let maximumRating: Double = 5.0
    
    public init(rating: Binding<Double>) {
        self._rating = rating
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { starIndex in
                    let starValue = Double(starIndex)
                    
                    Image(systemName: starIcon(for: starValue))
                        .font(.title2)
                        .foregroundColor(starColor(for: starValue))
                        .onTapGesture {
                            if rating == starValue {
                                rating = starValue - 0.5
                            } else if rating == starValue - 0.5 {
                                rating = starValue
                            } else {
                                rating = starValue
                            }
                        }
                }
            }
            
            Text(rating > 0 ? String(format: "%.1f de 5.0", rating) : "Toca las estrellas para calificar")
                .font(.subheadline)
                .foregroundColor(rating > 0 ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
        }
    }
    
    private func starIcon(for value: Double) -> String {
        if rating >= value {
            return "star.fill"
        } else if rating >= value - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    private func starColor(for value: Double) -> Color {
        if rating >= value - 0.5 {
            return Theme.Colors.imdb
        } else {
            return Theme.Colors.textTertiary
        }
    }
}

