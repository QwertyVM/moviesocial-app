import SwiftUI

/// Fondo con diseño de papel tapiz característico estilo WhatsApp Dark
public struct WhatsAppChatBackground: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            Theme.Colors.WhatsApp.chatBackground
                .ignoresSafeArea()
            
            // Textura sutil con iconos de cine y chat
            GeometryReader { geometry in
                let columns = Int(geometry.size.width / 80) + 1
                let rows = Int(geometry.size.height / 80) + 1
                
                VStack(spacing: 40) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: 40) {
                            ForEach(0..<columns, id: \.self) { c in
                                chatIcon(for: (r * columns + c) % 8)
                                    .opacity(0.04)
                                    .rotationEffect(.degrees(Double((r + c) % 4) * 15 - 15))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func chatIcon(for index: Int) -> some View {
        switch index {
        case 0:
            Image(systemName: "film")
                .font(.system(size: 20))
                .foregroundColor(.white)
        case 1:
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 18))
                .foregroundColor(.white)
        case 2:
            Image(systemName: "popcorn")
                .font(.system(size: 20))
                .foregroundColor(.white)
        case 3:
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
        case 4:
            Image(systemName: "play.rectangle")
                .font(.system(size: 18))
                .foregroundColor(.white)
        case 5:
            Image(systemName: "ticket")
                .font(.system(size: 18))
                .foregroundColor(.white)
        case 6:
            Image(systemName: "tv")
                .font(.system(size: 18))
                .foregroundColor(.white)
        default:
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
}

