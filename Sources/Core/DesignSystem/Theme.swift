import SwiftUI

/// Minimalist Cinema Theme for MovieSocial (High-End OLED Cinephile Design System)
public enum Theme {
    public enum Colors {
        // Monochromatic OLED Palette - Pure, quiet, cinema dark
        public static let background = Color(red: 10/255, green: 10/255, blue: 12/255)
        public static let surface = Color(red: 18/255, green: 18/255, blue: 22/255)
        public static let surfaceElevated = Color(red: 26/255, green: 26/255, blue: 32/255)
        public static let border = Color.white.opacity(0.08)
        public static let borderFocused = Color.white.opacity(0.20)
        
        public static let textPrimary = Color.white
        public static let textSecondary = Color(white: 0.68)
        public static let textTertiary = Color(white: 0.42)
        
        // External Ratings Accents (Refined & subtle)
        public static let rottenTomatoesCritics = Color(red: 245/255, green: 65/255, blue: 35/255)
        public static let rottenTomatoesAudience = Color(red: 250/255, green: 195/255, blue: 50/255)
        public static let imdb = Color(red: 245/255, green: 197/255, blue: 24/255)
        
        // Social Accent (Quiet Violet & Taste Fuchsia)
        public static let friendsAccent = Color(red: 129/255, green: 140/255, blue: 248/255) // Soft Indigo
        public static let recommendationAccent = Color(red: 217/255, green: 119/255, blue: 242/255) // Soft Orchid
        
        // WhatsApp Theme Tokens (Modern Minimalist Dark)
        public enum WhatsApp {
            public static let chatBackground = Color(red: 11/255, green: 14/255, blue: 18/255)
            public static let incomingBubble = Color(red: 24/255, green: 28/255, blue: 36/255)
            public static let outgoingBubble = Color(red: 15/255, green: 80/255, blue: 68/255)
            public static let accentGreen = Color(red: 0/255, green: 168/255, blue: 132/255)
            public static let inputBarBackground = Color(red: 20/255, green: 24/255, blue: 30/255)
            public static let inputFieldBackground = Color(red: 28/255, green: 34/255, blue: 42/255)
            public static let systemPillBackground = Color(red: 20/255, green: 26/255, blue: 32/255)
            public static let blueTicks = Color(red: 83/255, green: 189/255, blue: 235/255)
            public static let messageTime = Color(white: 0.55)
            public static let memberColors: [Color] = [
                Color(red: 83/255, green: 189/255, blue: 235/255),
                Color(red: 255/255, green: 173/255, blue: 71/255),
                Color(red: 229/255, green: 66/255, blue: 163/255),
                Color(red: 37/255, green: 211/255, blue: 102/255),
                Color(red: 186/255, green: 104/255, blue: 200/255),
                Color(red: 255/255, green: 128/255, blue: 171/255)
            ]
        }
    }
    
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
    }
    
    public enum Radius {
        public static let small: CGFloat = 6
        public static let medium: CGFloat = 10
        public static let large: CGFloat = 14
        public static let full: CGFloat = 999
    }
    
    public enum Typography {
        public static func system(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }
        
        public static func bold(size: CGFloat) -> Font {
            .system(size: size, weight: .bold)
        }
        
        public static func semibold(size: CGFloat) -> Font {
            .system(size: size, weight: .semibold)
        }
        
        public static func medium(size: CGFloat) -> Font {
            .system(size: size, weight: .medium)
        }
    }
}
