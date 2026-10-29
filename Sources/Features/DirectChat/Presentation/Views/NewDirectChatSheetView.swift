import SwiftUI

/// Modal para iniciar un nuevo chat One-to-One seleccionando a un amigo de la lista
public struct NewDirectChatSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var viewModel: DirectChatViewModel
    public let currentUser: User?
    public let onConversationStarted: (DirectConversation) -> Void
    
    public init(
        viewModel: DirectChatViewModel,
        currentUser: User?,
        onConversationStarted: @escaping (DirectConversation) -> Void
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onConversationStarted = onConversationStarted
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.WhatsApp.chatBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Barra de búsqueda de contactos
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        
                        TextField("Buscar amigo por nombre o @usuario...", text: $viewModel.friendSearchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                        
                        if !viewModel.friendSearchQuery.isEmpty {
                            Button {
                                viewModel.friendSearchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Theme.Colors.WhatsApp.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Listado de amigos disponibles
                    if viewModel.filteredFriends.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime.opacity(0.6))
                                .padding(.top, 50)
                            
                            Text("No se encontraron amigos")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            
                            Text("Añade amigos desde la pestaña Social para iniciar conversaciones privadas de cine.")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.filteredFriends) { friend in
                                    Button {
                                        guard let user = currentUser else { return }
                                        Task {
                                            if let conv = await viewModel.startChatWithFriend(friend, currentUser: user) {
                                                onConversationStarted(conv)
                                                dismiss()
                                            }
                                        }
                                    } label: {
                                        friendRow(friend)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NUEVO CHAT 1 A 1")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
            }
            .task {
                await viewModel.loadFriends()
            }
        }
    }
    
    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(red: 32/255, green: 44/255, blue: 51/255))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(String(friend.displayName.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(friend.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if friend.isMutual {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    }
                }
                
                HStack(spacing: 6) {
                    Text(friend.username)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    
                    if friend.mutualMoviesCount > 0 {
                        Text("• \(friend.mutualMoviesCount) en común")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
        }
        .padding(12)
        .background(Color(red: 20/255, green: 29/255, blue: 35/255))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

