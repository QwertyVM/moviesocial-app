import SwiftUI

public struct GroupDetailView: View {
    @Bindable public var viewModel: GroupsViewModel
    public let group: MovieGroup
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    @FocusState private var isInputFocused: Bool
    @State private var showingMovieInfoBanner: Bool = false
    
    public init(
        viewModel: GroupsViewModel,
        group: MovieGroup,
        currentUser: User?,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.group = group
        self.currentUser = currentUser
        self.onSelectMovie = onSelectMovie
    }
    
    // El grupo activo más actualizado
    private var activeGroup: MovieGroup {
        viewModel.selectedGroup ?? group
    }
    
    public var body: some View {
        ZStack {
            // Fondo con papel tapiz WhatsApp
            WhatsAppChatBackground()
            
            VStack(spacing: 0) {
                // Mensaje informativo o Toast flotante
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
                
                // Película en discusión (Banner compacto opcional estilo WhatsApp)
                if let movieTitle = activeGroup.currentMovieTitle, showingMovieInfoBanner {
                    moviePinnedBanner(title: movieTitle)
                }
                
                // Historial de mensajes de chat
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            // Mensaje informativo de cifrado/privacidad estilo WhatsApp
                            encryptionPill
                                .padding(.top, 12)
                                .padding(.bottom, 6)
                            
                            // Separador de fecha estilo WhatsApp
                            dateSeparatorPill("HOY")
                                .padding(.bottom, 6)
                            
                            if viewModel.isLoadingMessages && viewModel.currentGroupMessages.isEmpty {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.vertical, 30)
                            } else {
                                ForEach(viewModel.currentGroupMessages) { msg in
                                    messageRow(msg)
                                        .id(msg.id)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.currentGroupMessages.count) { _, _ in
                        if let last = viewModel.currentGroupMessages.last {
                            withAnimation(.spring(duration: 0.3)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Barra de texto inferior estilo WhatsApp
                whatsAppInputBar
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    viewModel.isViewingGroupInfo = true
                } label: {
                    HStack(spacing: 10) {
                        // Avatar circular del grupo
                        Text(activeGroup.iconEmoji)
                            .font(.system(size: 20))
                            .frame(width: 36, height: 36)
                            .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(activeGroup.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(participantsSubtitle)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 180, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                // Botón para alternar banner de la película asignada
                if activeGroup.currentMovieTitle != nil {
                    Button {
                        withAnimation {
                            showingMovieInfoBanner.toggle()
                        }
                    } label: {
                        Image(systemName: "film")
                            .font(.system(size: 15))
                            .foregroundColor(showingMovieInfoBanner ? Theme.Colors.WhatsApp.accentGreen : .white)
                    }
                }
                
                // Botón de Información del Grupo
                Button {
                    viewModel.isViewingGroupInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $viewModel.isViewingGroupInfo) {
            WhatsAppGroupInfoView(
                viewModel: viewModel,
                group: activeGroup,
                currentUser: currentUser,
                onSelectMovie: onSelectMovie
            )
        }
        .sheet(isPresented: $viewModel.isSharingMovieSheetPresented) {
            ShareMoviePickerSheet(
                viewModel: viewModel,
                currentUser: currentUser
            )
        }
        .sheet(isPresented: $viewModel.isAddingMembersSheetPresented) {
            AddFriendsToGroupSheet(
                viewModel: viewModel,
                group: activeGroup,
                currentUser: currentUser
            )
        }
        .task {
            await viewModel.selectGroup(group)
            await viewModel.loadFriends()
        }
    }
    
    // MARK: - Subtitle
    
    private var participantsSubtitle: String {
        var names: [String] = []
        if let user = currentUser, activeGroup.creatorId == user.id {
            names.append("Tú")
        } else {
            names.append(activeGroup.creatorName.components(separatedBy: " ").first ?? activeGroup.creatorName)
        }
        for member in activeGroup.members.prefix(3) {
            if let user = currentUser, member.id == user.id {
                if !names.contains("Tú") { names.append("Tú") }
            } else {
                let first = member.displayName.components(separatedBy: " ").first ?? member.displayName
                if !names.contains(first) { names.append(first) }
            }
        }
        if activeGroup.totalMembersCount > names.count {
            return "\(names.joined(separator: ", "))..."
        }
        return names.joined(separator: ", ")
    }
    
    // MARK: - Banner Película
    
    private func moviePinnedBanner(title: String) -> some View {
        HStack(spacing: 12) {
            if let poster = activeGroup.currentMoviePosterURL {
                AsyncImage(url: poster) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "film")
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    .frame(width: 32, height: 48)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("PELÍCULA EN DEBATE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let movieId = activeGroup.currentMovieId {
                Button {
                    onSelectMovie(movieId)
                } label: {
                    Text("Ver")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.Colors.WhatsApp.accentGreen)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Button {
                withAnimation {
                    showingMovieInfoBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(red: 20/255, green: 29/255, blue: 35/255))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    // MARK: - Message Row
    
    @ViewBuilder
    private func messageRow(_ msg: GroupMessage) -> some View {
        switch msg.messageType {
        case .system:
            systemPill(msg.text)
        case .movieShare:
            movieShareBubble(msg)
        case .text:
            textBubble(msg)
        }
    }
    
    // MARK: - WhatsApp Bubbles
    
    private func textBubble(_ msg: GroupMessage) -> some View {
        let isMe = msg.userId == currentUser?.id
        
        return HStack(alignment: .bottom, spacing: 4) {
            if isMe {
                Spacer(minLength: 45)
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                // Remitente (solo en mensajes entrantes de otros miembros)
                if !isMe {
                    Text(msg.userName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(senderColor(for: msg.userId))
                        .padding(.bottom, 1)
                }
                
                // Texto y hora con estilo WhatsApp
                HStack(alignment: .bottom, spacing: 8) {
                    Text(msg.text)
                        .font(.system(size: 14.5))
                        .foregroundColor(Color(red: 233/255, green: 237/255, blue: 239/255))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Hora y doble tick
                    HStack(spacing: 3) {
                        Text(msg.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        
                        if isMe {
                            // Doble tick azul de WhatsApp
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
    
    private func movieShareBubble(_ msg: GroupMessage) -> some View {
        let isMe = msg.userId == currentUser?.id
        
        return HStack(alignment: .bottom, spacing: 4) {
            if isMe { Spacer(minLength: 40) }
            
            VStack(alignment: .leading, spacing: 8) {
                if !isMe {
                    Text(msg.userName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(senderColor(for: msg.userId))
                }
                
                // Tarjeta de película compartida (estilo WhatsApp rich media)
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
                
                // Comentario que acompaña a la película
                if !msg.text.isEmpty {
                    Text(msg.text)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 233/255, green: 237/255, blue: 239/255))
                }
                
                // Hora y ticks
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
    
    // MARK: - WhatsApp Center Pills
    
    private var encryptionPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
            Text("Los mensajes y debates de este cineclub son privados entre miembros.")
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
        .shadow(color: .black.opacity(0.15), radius: 1)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
    
    // MARK: - WhatsApp Input Bar
    
    private var whatsAppInputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Botón de adjuntar / opciones (+ estilo WhatsApp)
            Menu {
                Button {
                    viewModel.isSharingMovieSheetPresented = true
                } label: {
                    Label("Compartir Película", systemImage: "film")
                }
                
                Button {
                    viewModel.copyInviteLink(for: activeGroup)
                } label: {
                    Label("Copiar Enlace de Invitación", systemImage: "link")
                }
                
                Button {
                    viewModel.isAddingMembersSheetPresented = true
                } label: {
                    Label("Añadir Amigos al Grupo", systemImage: "person.badge.plus")
                }
                
                Button {
                    viewModel.isViewingGroupInfo = true
                } label: {
                    Label("Información del Grupo", systemImage: "info.circle")
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
            
            // Campo de texto estilo píldora WhatsApp
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
                
                // Botón rápido para compartir película directamente
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
            
            // Botón circular de enviar verde WhatsApp
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
            _ = await viewModel.sendMessage(user: user)
        }
    }
    
    private func senderColor(for userId: String) -> Color {
        let colors = Theme.Colors.WhatsApp.memberColors
        let hash = abs(userId.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - WhatsApp Group Info View (Sheet de Información del Grupo)

public struct WhatsAppGroupInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var viewModel: GroupsViewModel
    public let group: MovieGroup
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    public init(
        viewModel: GroupsViewModel,
        group: MovieGroup,
        currentUser: User?,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.group = group
        self.currentUser = currentUser
        self.onSelectMovie = onSelectMovie
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 11/255, green: 20/255, blue: 26/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Avatar Grande del Grupo
                        VStack(spacing: 12) {
                            Text(group.iconEmoji)
                                .font(.system(size: 56))
                                .frame(width: 96, height: 96)
                                .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            
                            VStack(spacing: 4) {
                                Text(group.name)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("Cineclub · \(group.totalMembersCount) participantes")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        // Acciones Rápidas (Añadir amigos, Enlace, Película)
                        HStack(spacing: 24) {
                            quickActionButton(icon: "person.badge.plus", label: "Añadir") {
                                viewModel.isAddingMembersSheetPresented = true
                            }
                            
                            quickActionButton(icon: "link", label: "Enlace") {
                                viewModel.copyInviteLink(for: group)
                            }
                            
                            quickActionButton(icon: "film", label: "Película") {
                                viewModel.isSharingMovieSheetPresented = true
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Tarjeta: Descripción
                        if !group.description.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("DESCRIPCIÓN DEL GRUPO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                
                                Text(group.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineSpacing(3)
                                
                                Text("Creado por \(group.creatorName) el \(group.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                    .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Tarjeta: Enlace de Invitación al Grupo (¡Característica clave!)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enlace de invitación al grupo")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Cualquiera con este enlace puede unirse al chat")
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                }
                            }
                            
                            HStack {
                                Text(group.inviteLink)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(group.inviteCode)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.Colors.WhatsApp.accentGreen.opacity(0.2))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            HStack(spacing: 12) {
                                Button {
                                    viewModel.copyInviteLink(for: group)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copiar enlace")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Theme.Colors.WhatsApp.accentGreen)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                
                                #if os(iOS)
                                ShareLink(item: group.inviteLink, subject: Text("Únete a «\(group.name)»"), message: Text("¡Hola! Únete a mi cineclub «\(group.name)» en MovieSocial:")) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Compartir")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                #else
                                Button {
                                    viewModel.copyInviteLink(for: group)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Compartir")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                #endif
                            }
                        }
                        .padding(14)
                        .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Tarjeta: Película en debate
                        if let movieTitle = group.currentMovieTitle {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PELÍCULA EN DISCUSIÓN")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                
                                HStack(spacing: 12) {
                                    if let poster = group.currentMoviePosterURL {
                                        AsyncImage(url: poster) { img in
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle().fill(Color.gray.opacity(0.3))
                                        }
                                        .frame(width: 44, height: 66)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 44, height: 66)
                                            .overlay(Image(systemName: "film").foregroundColor(.gray))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(movieTitle)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        if let year = group.currentMovieYear {
                                            Text("\(year)")
                                                .font(.caption)
                                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                        }
                                        
                                        if let movieId = group.currentMovieId {
                                            Button {
                                                dismiss()
                                                onSelectMovie(movieId)
                                            } label: {
                                                Text("Ver ficha completa")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                                    .padding(.top, 2)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(14)
                            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Tarjeta: Participantes
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(group.totalMembersCount) PARTICIPANTES")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                .padding(.horizontal, 14)
                                .padding(.top, 14)
                                .padding(.bottom, 8)
                            
                            // Botón Añadir Amigos
                            Button {
                                viewModel.isAddingMembersSheetPresented = true
                            } label: {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(Theme.Colors.WhatsApp.accentGreen)
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Image(systemName: "person.badge.plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text("Añadir participantes")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 64)
                            
                            // Botón Enlace de Invitación
                            Button {
                                viewModel.copyInviteLink(for: group)
                            } label: {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(Color(red: 32/255, green: 44/255, blue: 51/255))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Image(systemName: "link")
                                                .font(.system(size: 16))
                                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                        )
                                    
                                    Text("Enlace de invitación al grupo")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 64)
                            
                            // Creador / Admin
                            participantRow(
                                name: group.creatorName,
                                subtitle: "Creador del grupo",
                                isAdmin: true,
                                isMe: currentUser?.id == group.creatorId
                            )
                            
                            // Lista de Miembros
                            ForEach(group.members) { member in
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 64)
                                
                                participantRow(
                                    name: member.displayName,
                                    subtitle: member.username,
                                    isAdmin: false,
                                    isMe: currentUser?.id == member.id
                                )
                            }
                        }
                        .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Botón de salir
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Cerrar")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Info. del grupo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                }
            }
        }
    }
    
    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 32/255, green: 44/255, blue: 51/255))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    )
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func participantRow(name: String, subtitle: String, isAdmin: Bool, isMe: Bool) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(red: 42/255, green: 57/255, blue: 66/255))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    if isMe {
                        Text("(Tú)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
            }
            
            Spacer()
            
            if isAdmin {
                Text("Admin del grupo")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.WhatsApp.accentGreen.opacity(0.2))
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Añadir Amigos al Grupo Existente Sheet

public struct AddFriendsToGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var viewModel: GroupsViewModel
    public let group: MovieGroup
    public let currentUser: User?
    
    public init(
        viewModel: GroupsViewModel,
        group: MovieGroup,
        currentUser: User?
    ) {
        self.viewModel = viewModel
        self.group = group
        self.currentUser = currentUser
    }
    
    private var availableFriends: [Friend] {
        let existingIds = Set(group.members.map(\.id) + [group.creatorId])
        return viewModel.allFriends.filter { !existingIds.contains($0.id) }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 11/255, green: 20/255, blue: 26/255)
                    .ignoresSafeArea()
                
                if availableFriends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 44))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        Text("Todos tus amigos ya están en este cineclub")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Comparte el enlace de invitación para que otros amigos se unan.")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            viewModel.copyInviteLink(for: group)
                            dismiss()
                        } label: {
                            Label("Copiar Enlace de Invitación", systemImage: "link")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Theme.Colors.WhatsApp.accentGreen)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Chips de amigos seleccionados
                        if !viewModel.selectedFriendsToAddIds.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(availableFriends.filter { viewModel.selectedFriendsToAddIds.contains($0.id) }) { friend in
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color(red: 42/255, green: 57/255, blue: 66/255))
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Text(String(friend.displayName.prefix(1)))
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                            Text(friend.displayName)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                            
                                            Button {
                                                viewModel.selectedFriendsToAddIds.remove(friend.id)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                        }
                        
                        List(availableFriends) { friend in
                            let isSelected = viewModel.selectedFriendsToAddIds.contains(friend.id)
                            Button {
                                if isSelected {
                                    viewModel.selectedFriendsToAddIds.remove(friend.id)
                                } else {
                                    viewModel.selectedFriendsToAddIds.insert(friend.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(red: 42/255, green: 57/255, blue: 66/255))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(friend.displayName.prefix(1)))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.displayName)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("\(friend.username) · \(friend.mutualMoviesCount) películas")
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(isSelected ? Theme.Colors.WhatsApp.accentGreen : Theme.Colors.WhatsApp.messageTime)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color(red: 20/255, green: 29/255, blue: 35/255))
                        }
                        #if os(iOS)
                        .listStyle(.plain)
                        #endif
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Añadir participantes")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir (\(viewModel.selectedFriendsToAddIds.count))") {
                        guard let user = currentUser else { return }
                        Task {
                            _ = await viewModel.addFriendsToCurrentGroup(user: user)
                            dismiss()
                        }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(viewModel.selectedFriendsToAddIds.isEmpty ? Theme.Colors.WhatsApp.messageTime : Theme.Colors.WhatsApp.accentGreen)
                    .disabled(viewModel.selectedFriendsToAddIds.isEmpty)
                }
            }
        }
    }
}

// MARK: - Sheet para Compartir Película en el Chat

public struct ShareMoviePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var viewModel: GroupsViewModel
    public let currentUser: User?
    
    @State private var optionalComment: String = ""
    @State private var selectedMovie: Movie?
    
    public init(viewModel: GroupsViewModel, currentUser: User?) {
        self.viewModel = viewModel
        self.currentUser = currentUser
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 11/255, green: 20/255, blue: 26/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Barra de búsqueda
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        TextField("Buscar película para recomendar...", text: $viewModel.movieSearchQuery)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .onChange(of: viewModel.movieSearchQuery) { _, newValue in
                                Task {
                                    await viewModel.searchMovies(query: newValue)
                                }
                            }
                    }
                    .padding(10)
                    .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    if let movie = selectedMovie {
                        // Tarjeta de película seleccionada
                        VStack(spacing: 10) {
                            HStack(spacing: 12) {
                                if let poster = movie.posterURL {
                                    AsyncImage(url: poster) { img in
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle().fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 44, height: 66)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(movie.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("\(movie.releaseYear)")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                }
                                
                                Spacer()
                                
                                Button {
                                    selectedMovie = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            TextField("Añadir un comentario (opcional)...", text: $optionalComment)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button {
                                guard let user = currentUser else { return }
                                Task {
                                    _ = await viewModel.shareMovie(movie: movie, note: optionalComment, user: user)
                                    dismiss()
                                }
                            } label: {
                                Text("Compartir en el Cineclub")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(Theme.Colors.WhatsApp.accentGreen)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(14)
                        .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                    
                    // Resultados
                    if viewModel.isSearchingMovies {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 20)
                        Spacer()
                    } else if viewModel.movieSearchResults.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "film")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                            Text("Escribe el nombre de una película")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        }
                        .padding(.top, 40)
                        Spacer()
                    } else {
                        List(viewModel.movieSearchResults) { movie in
                            Button {
                                selectedMovie = movie
                            } label: {
                                HStack(spacing: 12) {
                                    if let poster = movie.posterURL {
                                        AsyncImage(url: poster) { img in
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle().fill(Color.gray.opacity(0.3))
                                        }
                                        .frame(width: 36, height: 54)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(movie.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("\(movie.releaseYear)")
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "paperplane.circle.fill")
                                        .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color(red: 20/255, green: 29/255, blue: 35/255))
                        }
                        #if os(iOS)
                        .listStyle(.plain)
                        #endif
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Compartir Película")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
            }
        }
    }
}
