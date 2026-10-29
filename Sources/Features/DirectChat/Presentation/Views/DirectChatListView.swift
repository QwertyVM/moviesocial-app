import SwiftUI

/// Vista principal de la sección de Chats One-to-One (1 a 1)
public struct DirectChatListView: View {
    @Bindable public var viewModel: DirectChatViewModel
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    @State private var navigationDestinationConversation: DirectConversation?
    
    public init(
        viewModel: DirectChatViewModel,
        currentUser: User?,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onSelectMovie = onSelectMovie
    }
    
    public var body: some View {
        ZStack {
            Theme.Colors.WhatsApp.chatBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Buscador de chats directos
                searchBar
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                
                // Barra de acceso rápido
                quickActionsBar
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.conversations.isEmpty {
                    emptyChatsView
                } else if viewModel.filteredConversations.isEmpty {
                    emptySearchResultsView
                } else {
                    conversationsList
                }
            }
        }
        .sheet(isPresented: $viewModel.isStartingNewChat) {
            NewDirectChatSheetView(
                viewModel: viewModel,
                currentUser: currentUser,
                onConversationStarted: { conv in
                    navigationDestinationConversation = conv
                }
            )
        }
        .navigationDestination(item: $navigationDestinationConversation) { conv in
            DirectChatDetailView(
                viewModel: viewModel,
                conversation: conv,
                currentUser: currentUser,
                onSelectMovie: onSelectMovie
            )
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                .font(.system(size: 14))
            
            TextField("Buscar en chats directos...", text: $viewModel.searchQuery)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.Colors.WhatsApp.inputFieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var quickActionsBar: some View {
        Button {
            viewModel.isStartingNewChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.bubble.fill")
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    .font(.system(size: 15))
                
                Text("Nuevo Chat 1 a 1 con un Amigo")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.WhatsApp.accentGreen.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredConversations) { conv in
                    NavigationLink {
                        DirectChatDetailView(
                            viewModel: viewModel,
                            conversation: conv,
                            currentUser: currentUser,
                            onSelectMovie: onSelectMovie
                        )
                    } label: {
                        chatRow(conv)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.leading, 72)
                }
            }
            .background(Color(red: 17/255, green: 27/255, blue: 33/255))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 14)
            .padding(.bottom, 24)
        }
        .refreshable {
            if let user = currentUser {
                await viewModel.loadConversations(userId: user.id)
            }
        }
    }
    
    private func chatRow(_ conv: DirectConversation) -> some View {
        HStack(spacing: 14) {
            // Avatar Circular del Amigo
            Circle()
                .fill(Color(red: 32/255, green: 44/255, blue: 51/255))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(conv.participant.displayName.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            
            // Textos centrales
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conv.participant.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let last = conv.lastMessage {
                        Text(last.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(conv.unreadCount > 0 ? Theme.Colors.WhatsApp.accentGreen : Theme.Colors.WhatsApp.messageTime)
                    }
                }
                
                HStack(spacing: 4) {
                    if let last = conv.lastMessage {
                        if last.senderId == currentUser?.id {
                            Text("Tú:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        }
                        
                        if last.messageType == .movieShare {
                            Image(systemName: "film.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            Text(last.sharedMovieTitle ?? "Película compartida")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                .lineLimit(1)
                        } else {
                            Text(last.text)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Inicia una conversación...")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    if conv.unreadCount > 0 {
                        Text("\(conv.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.WhatsApp.accentGreen)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    // MARK: - Empty States
    
    private var emptyChatsView: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 46))
                .foregroundColor(Theme.Colors.WhatsApp.messageTime.opacity(0.6))
                .padding(.top, 40)
            
            Text("No tienes chats 1 a 1 todavía")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Inicia un chat privado con cualquiera de tus amigos para compartir y debatir películas.")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                viewModel.isStartingNewChat = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.bubble.fill")
                    Text("Iniciar Chat 1 a 1")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.Colors.WhatsApp.accentGreen)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            
            Spacer()
        }
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundColor(Theme.Colors.WhatsApp.messageTime.opacity(0.6))
                .padding(.top, 40)
            
            Text("Sin resultados para «\(viewModel.searchQuery)»")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text("Comprueba que el nombre del amigo o el contenido del chat sea correcto.")
                .font(.caption)
                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
            
            Spacer()
        }
    }
}

