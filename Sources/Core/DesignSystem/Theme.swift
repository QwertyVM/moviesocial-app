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
        public static let recommendationAccent = Color(red: 232/255, green: 121/255, blue: 249/255) // Neon Fuchsia/Purple
        
        // WhatsApp Theme Tokens
        public enum WhatsApp {
            public static let chatBackground = Color(red: 11/255, green: 20/255, blue: 26/255) // #0B141A
            public static let incomingBubble = Color(red: 32/255, green: 44/255, blue: 51/255) // #202C33
            public static let outgoingBubble = Color(red: 0/255, green: 92/255, blue: 75/255) // #005C4B
            public static let accentGreen = Color(red: 0/255, green: 168/255, blue: 132/255) // #00A884
            public static let inputBarBackground = Color(red: 31/255, green: 44/255, blue: 52/255) // #1F2C34
            public static let inputFieldBackground = Color(red: 42/255, green: 57/255, blue: 66/255) // #2A3942
            public static let systemPillBackground = Color(red: 24/255, green: 34/255, blue: 41/255) // #182229
            public static let blueTicks = Color(red: 83/255, green: 189/255, blue: 235/255) // #53BDEB
            public static let messageTime = Color(red: 134/255, green: 150/255, blue: 160/255) // #8696A0
            public static let memberColors: [Color] = [
                Color(red: 83/255, green: 189/255, blue: 235/255), // Cyan
                Color(red: 255/255, green: 173/255, blue: 71/255), // Amber
                Color(red: 229/255, green: 66/255, blue: 163/255), // Pink
                Color(red: 37/255, green: 211/255, blue: 102/255), // Green
                Color(red: 186/255, green: 104/255, blue: 200/255), // Purple
                Color(red: 255/255, green: 128/255, blue: 171/255)  // Coral
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
        public static let large: CGFloat = 16
        public static let full: CGFloat = 999
    }
}

