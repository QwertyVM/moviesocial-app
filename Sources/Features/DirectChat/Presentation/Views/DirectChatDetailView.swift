import SwiftUI

/// Vista de Detalle de Chat One-to-One estilo WhatsApp Dark
public struct DirectChatDetailView: View {
    @Bindable public var viewModel: DirectChatViewModel
    public let conversation: DirectConversation
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    @FocusState private var isInputFocused: Bool
    
    public init(
        viewModel: DirectChatViewModel,
        conversation: DirectConversation,
        currentUser: User?,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.conversation = conversation
        self.currentUser = currentUser
        self.onSelectMovie = onSelectMovie
    }
    
    private var activeConversation: DirectConversation {
        viewModel.selectedConversation ?? conversation
    }
    
    public var body: some View {
        ZStack {
            // Fondo con papel tapiz WhatsApp
            WhatsAppChatBackground()
            
            VStack(spacing: 0) {
                // Toast flotante si existe
                if let toast = viewModel.toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        Text(toast)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 20/255, green: 30/255, blue: 36/255))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.Colors.WhatsApp.accentGreen.opacity(0.6), lineWidth: 1))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
                
                // Historial de mensajes
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            // Píldora de privacidad estilo WhatsApp
                            privacyPill
                                .padding(.top, 12)
                                .padding(.bottom, 6)
                            
                            // Separador de fecha
                            dateSeparatorPill("HOY")
                                .padding(.bottom, 6)
                            
                            if viewModel.isLoadingMessages && viewModel.currentMessages.isEmpty {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.vertical, 30)
                            } else {
                                ForEach(viewModel.currentMessages) { msg in
                                    messageRow(msg)
                                        .id(msg.id)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.currentMessages.count) { _, _ in
                        if let last = viewModel.currentMessages.last {
                            withAnimation(.spring(duration: 0.3)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Barra de texto inferior WhatsApp
                inputBar
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(red: 32/255, green: 44/255, blue: 51/255))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(activeConversation.participant.displayName.prefix(1)))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(activeConversation.participant.displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("\(activeConversation.participant.username) • \(activeConversation.participant.mutualMoviesCount) en común")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 190, alignment: .leading)
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.isSharingMovieSheetPresented = true
                } label: {
                    Image(systemName: "film")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                }
            }
        }
        .sheet(isPresented: $viewModel.isSharingMovieSheetPresented) {
            DirectShareMoviePickerSheet(
                viewModel: viewModel,
                currentUser: currentUser
            )
        }
        .task {
            if let user = currentUser {
                await viewModel.selectConversation(activeConversation, currentUserId: user.id)
            }
        }
    }
    
    // MARK: - Message Rows
    
    @ViewBuilder
    private func messageRow(_ msg: DirectMessage) -> some View {
        switch msg.messageType {
        case .system:
            systemPill(msg.text)
        case .movieShare:
            movieShareBubble(msg)
        case .text:
            textBubble(msg)
        }
    }
    
    private func textBubble(_ msg: DirectMessage) -> some View {
        let isMe = msg.senderId == currentUser?.id
        
        return HStack(alignment: .bottom, spacing: 4) {
            if isMe {
                Spacer(minLength: 45)
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(msg.text)
                        .font(.system(size: 14.5))
                        .foregroundColor(Color(red: 233/255, green: 237/255, blue: 239/255))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 3) {
                        Text(msg.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        
                        if isMe {
                            Text("✓✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.Colors.WhatsApp.blueTicks)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isMe ? Theme.Colors.WhatsApp.outgoingBubble : Theme.Colors.WhatsApp.incomingBubble)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: isMe ? 12 : 3,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: isMe ? 3 : 12,
                    topTrailingRadius: 12
                )
            )
            .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            
            if !isMe {
                Spacer(minLength: 45)
            }
        }
    }
    
    private func movieShareBubble(_ msg: DirectMessage) -> some View {
        let isMe = msg.senderId == currentUser?.id
        
        return HStack(alignment: .bottom, spacing: 4) {
            if isMe { Spacer(minLength: 40) }
            
            VStack(alignment: .leading, spacing: 8) {
                // Tarjeta de película recomendada 1 a 1
                HStack(spacing: 10) {
                    if let poster = msg.sharedMoviePosterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 52, height: 78)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 52, height: 78)
                            .overlay(Image(systemName: "film").foregroundColor(.gray))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(msg.sharedMovieTitle ?? "Película recomendada")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if let year = msg.sharedMovieYear {
                            Text("\(year)")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        }
                        
                        if let movieId = msg.sharedMovieId {
                            Button {
                                onSelectMovie(movieId)
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Ver ficha")
                                        .font(.system(size: 11, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                .padding(.top, 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if !msg.text.isEmpty {
                    Text(msg.text)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 233/255, green: 237/255, blue: 239/255))
                }
                
                HStack {
                    Spacer()
                    Text(msg.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    
                    if isMe {
                        Text("✓✓")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.Colors.WhatsApp.blueTicks)
                    }
                }
            }
            .padding(10)
            .background(isMe ? Theme.Colors.WhatsApp.outgoingBubble : Theme.Colors.WhatsApp.incomingBubble)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: isMe ? 12 : 3,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: isMe ? 3 : 12,
                    topTrailingRadius: 12
                )
            )
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            if !isMe { Spacer(minLength: 40) }
        }
    }
    
    // MARK: - Center Pills
    
    private var privacyPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
            Text("Mensajes privados cifrados de extremo a extremo entre tú y \(activeConversation.participant.displayName).")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
        }
        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.Colors.WhatsApp.systemPillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 1)
        .frame(maxWidth: .infinity)
    }
    
    private func dateSeparatorPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.Colors.WhatsApp.systemPillBackground)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 1)
            .frame(maxWidth: .infinity)
    }
    
    private func systemPill(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
            Text(text)
                .font(.system(size: 11.5))
                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.Colors.WhatsApp.systemPillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Menú de opciones
            Menu {
                Button {
                    viewModel.isSharingMovieSheetPresented = true
                } label: {
                    Label("Compartir Película", systemImage: "film")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    .frame(width: 40, height: 40)
                    .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Campo de texto estilo WhatsApp
            HStack(spacing: 8) {
                #if os(iOS)
                TextField("Mensaje", text: $viewModel.newMessageText, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendTextMessage()
                    }
                #else
                TextField("Mensaje", text: $viewModel.newMessageText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendTextMessage()
                    }
                #endif
                
                Button {
                    viewModel.isSharingMovieSheetPresented = true
                } label: {
                    Image(systemName: "film")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Theme.Colors.WhatsApp.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            
            // Botón enviar
            Button {
                sendTextMessage()
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.WhatsApp.accentGreen)
                        .frame(width: 42, height: 42)
                    
                    let isEmpty = viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    Image(systemName: isEmpty ? "mic.fill" : "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.Colors.WhatsApp.inputBarBackground)
    }
    
    private func sendTextMessage() {
        guard let user = currentUser else { return }
        Task {
            _ = await viewModel.sendMessage(currentUser: user)
        }
    }
}

