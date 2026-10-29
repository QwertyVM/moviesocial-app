import SwiftUI

/// Minimalist Cinema Theme for MovieSocial
public enum Theme {
    public enum Colors {
        // Core monochromatic palette (Cinema OLED Dark)
        public static let background = Color(red: 11/255, green: 12/255, blue: 14/255)
        public static let surface = Color(red: 20/255, green: 22/255, blue: 27/255)
        public static let surfaceElevated = Color(red: 28/255, green: 31/255, blue: 38/255)
        public static let border = Color(red: 38/255, green: 42/255, blue: 51/255)
        
        public static let textPrimary = Color.white
        public static let textSecondary = Color(red: 148/255, green: 153/255, blue: 166/255)
        public static let textTertiary = Color(red: 90/255, green: 95/255, blue: 108/255)
        
        // External Ratings Accents
        public static let rottenTomatoesCritics = Color(red: 250/255, green: 50/255, blue: 10/255) // Tomato Red
        public static let rottenTomatoesAudience = Color(red: 255/255, green: 206/255, blue: 49/255) // Popcorn Gold
        public static let imdb = Color(red: 245/255, green: 197/255, blue: 24/255) // IMDb Yellow
        
        // Social Accent
        public static let friendsAccent = Color(red: 99/255, green: 102/255, blue: 241/255) // Indigo/Violet
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
        public static let large: CGFloat = 16
        public static let full: CGFloat = 999
    }
}

