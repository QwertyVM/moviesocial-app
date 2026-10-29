import SwiftUI

public struct GroupsListView: View {
    @Bindable public var viewModel: GroupsViewModel
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    public let isEmbedded: Bool
    
    private let availableEmojis = ["🎬", "🍿", "🚀", "🎭", "🔪", "🎞️", "👽", "🏎️", "🌟", "👾", "🧙‍♂️", "🕵️‍♂️"]
    
    public init(
        viewModel: GroupsViewModel,
        currentUser: User?,
        isEmbedded: Bool = false,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.isEmbedded = isEmbedded
        self.onSelectMovie = onSelectMovie
    }
    
    public var body: some View {
        if isEmbedded {
            mainZStackContent
        } else {
            NavigationStack {
                mainZStackContent
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("CINECLUBS Y GRUPOS")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .tracking(3)
                                .foregroundColor(.white)
                        }
                        
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button {
                                viewModel.isJoiningViaLink = true
                            } label: {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            }
                            
                            Button {
                                viewModel.startGroupCreation()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            }
                        }
                    }
            }
        }
    }
    
    private var mainZStackContent: some View {
        ZStack {
            Theme.Colors.WhatsApp.chatBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Toast flotante
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
                
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.groups.isEmpty {
                    emptyGroupsView
                } else {
                    groupsContentList
                }
            }
        }
        .sheet(isPresented: $viewModel.isCreatingGroup) {
            createGroupWhatsAppFlowSheet
        }
        .sheet(isPresented: $viewModel.isJoiningViaLink) {
            joinByLinkSheet
        }
        .task {
            if viewModel.groups.isEmpty {
                await viewModel.loadGroups()
            }
            await viewModel.loadFriends()
        }
    }
    
    // MARK: - Subviews
    
    private var groupsContentList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Barra de accesos directos estilo WhatsApp
                HStack(spacing: 12) {
                    Button {
                        viewModel.startGroupCreation()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            Text("Nuevo Grupo")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        viewModel.isJoiningViaLink = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            Text("Unirse con Enlace")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                
                // Lista de Grupos estilo lista de Chats de WhatsApp
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.groups) { group in
                        NavigationLink {
                            GroupDetailView(
                                viewModel: viewModel,
                                group: group,
                                currentUser: currentUser,
                                onSelectMovie: onSelectMovie
                            )
                        } label: {
                            whatsAppChatRow(group)
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
                .padding(.top, 4)
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.loadGroups()
        }
    }
    
    // MARK: - Row estilo WhatsApp Chat List
    
    private func whatsAppChatRow(_ group: MovieGroup) -> some View {
        HStack(spacing: 14) {
            // Avatar Circular con Emoji
            ZStack {
                Circle()
                    .fill(Color(red: 32/255, green: 44/255, blue: 51/255))
                    .frame(width: 50, height: 50)
                
                Text(group.iconEmoji)
                    .font(.system(size: 26))
            }
            
            // Textos centrales
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Fecha/Hora
                    Text(group.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
                
                HStack(spacing: 4) {
                    if let movie = group.currentMovieTitle {
                        Image(systemName: "film.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        Text(movie)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            .lineLimit(1)
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    }
                    
                    Text("\(group.totalMembersCount) miembros")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if group.messagesCount > 0 {
                        Text("\(group.messagesCount)")
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
    
    // MARK: - Vista vacía
    
    private var emptyGroupsView: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
            Text("Aún no tienes cineclubs o grupos")
                .font(.headline.bold())
                .foregroundColor(.white)
            Text("Crea un grupo añadiendo amigos o compartiendo un enlace de invitación.")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            VStack(spacing: 10) {
                Button {
                    viewModel.startGroupCreation()
                } label: {
                    Label("Crear mi primer cineclub", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.Colors.WhatsApp.accentGreen)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    viewModel.isJoiningViaLink = true
                } label: {
                    Label("Unirse con enlace de invitación", systemImage: "link")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 10)
        }
        .padding(24)
    }
    
    // MARK: - Flujo de Creación de Grupo estilo WhatsApp (Añadir amigos o enlace)
    
    private var createGroupWhatsAppFlowSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 11/255, green: 20/255, blue: 26/255)
                    .ignoresSafeArea()
                
                if viewModel.createStep == 0 {
                    // PASO 1: AÑADIR AMIGOS / PARTICIPANTES
                    step1AddFriendsView
                } else {
                    // PASO 2: ASUNTO, ICONO Y ENLACE DE INVITACIÓN
                    step2GroupDetailsView
                }
            }
            .navigationTitle(viewModel.createStep == 0 ? "Nuevo grupo" : "Información del grupo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.createStep == 0 ? "Cancelar" : "Atrás") {
                        if viewModel.createStep == 1 {
                            viewModel.createStep = 0
                        } else {
                            viewModel.isCreatingGroup = false
                        }
                    }
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.createStep == 0 {
                        Button("Siguiente") {
                            viewModel.proceedToDetailsStep()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    } else {
                        Button("Crear") {
                            guard let user = currentUser else { return }
                            Task {
                                _ = await viewModel.createGroup(creator: user)
                            }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.newGroupName.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.Colors.WhatsApp.messageTime : Theme.Colors.WhatsApp.accentGreen)
                        .disabled(viewModel.newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
    
    // MARK: - Paso 1: Añadir Amigos
    
    private var step1AddFriendsView: some View {
        VStack(spacing: 0) {
            // Subtítulo con contador de seleccionados
            HStack {
                Text("AÑADIR PARTICIPANTES")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                Spacer()
                Text("\(viewModel.selectedFriendIds.count) seleccionados")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
            
            // Barra de búsqueda de amigos
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                TextField("Buscar amigos...", text: $viewModel.friendSearchQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(Color(red: 32/255, green: 44/255, blue: 51/255))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            
            // Chips horizontales de amigos seleccionados (idéntico a WhatsApp)
            if !viewModel.selectedFriends.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.selectedFriends) { friend in
                            VStack(spacing: 4) {
                                ZStack(alignment: .topTrailing) {
                                    Circle()
                                        .fill(Color(red: 42/255, green: 57/255, blue: 66/255))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(String(friend.displayName.prefix(1)))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Button {
                                        viewModel.removeSelectedFriend(friendId: friend.id)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                            .background(Color.black.clipShape(Circle()))
                                    }
                                    .offset(x: 4, y: -4)
                                }
                                
                                Text(friend.displayName.components(separatedBy: " ").first ?? friend.displayName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .frame(width: 58)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(red: 20/255, green: 29/255, blue: 35/255))
            }
            
            // Banner explicativo para invitar por enlace directo
            HStack(spacing: 10) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("¿Prefieres invitar mediante enlace?")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Puedes continuar sin añadir amigos ahora y compartir el enlace de invitación después.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
                
                Spacer()
                
                Button {
                    viewModel.proceedToDetailsStep()
                } label: {
                    Text("Saltar →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                }
            }
            .padding(12)
            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Lista de Amigos
            List(viewModel.filteredFriends) { friend in
                let isSelected = viewModel.selectedFriendIds.contains(friend.id)
                Button {
                    viewModel.toggleFriendSelection(friendId: friend.id)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(red: 42/255, green: 57/255, blue: 66/255))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(friend.displayName.prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
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
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color(red: 20/255, green: 29/255, blue: 35/255))
            }
            #if os(iOS)
            .listStyle(.plain)
            #endif
            .scrollContentBackground(.hidden)
            
            // Botón Siguiente flotante en la parte inferior estilo WhatsApp
            Button {
                viewModel.proceedToDetailsStep()
            } label: {
                HStack {
                    Text(viewModel.selectedFriendIds.isEmpty ? "Continuar con Enlace de Invitación" : "Siguiente (\(viewModel.selectedFriendIds.count) amigos)")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.Colors.WhatsApp.accentGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
        }
    }
    
    // MARK: - Paso 2: Datos del Grupo & Enlace de Invitación
    
    private var step2GroupDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabecera: Icono y Nombre del grupo (como en WhatsApp)
                HStack(spacing: 16) {
                    // Icono seleccionado
                    Menu {
                        ForEach(availableEmojis, id: \.self) { emoji in
                            Button {
                                viewModel.selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                            }
                        }
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color(red: 32/255, green: 44/255, blue: 51/255))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Text(viewModel.selectedEmoji)
                                        .font(.system(size: 34))
                                )
                            
                            Circle()
                                .fill(Theme.Colors.WhatsApp.accentGreen)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Asunto del grupo (ej: Fans de Nolan)", text: $viewModel.newGroupName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        
                        Divider()
                            .background(Theme.Colors.WhatsApp.accentGreen)
                    }
                }
                .padding(.top, 8)
                
                // Selector rápido de emojis de cine
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableEmojis, id: \.self) { emoji in
                            Button {
                                viewModel.selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 42, height: 42)
                                    .background(viewModel.selectedEmoji == emoji ? Theme.Colors.WhatsApp.accentGreen.opacity(0.3) : Color(red: 32/255, green: 44/255, blue: 51/255))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(viewModel.selectedEmoji == emoji ? Theme.Colors.WhatsApp.accentGreen : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Descripción
                VStack(alignment: .leading, spacing: 6) {
                    Text("DESCRIPCIÓN O REGLAS (OPCIONAL)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    
                    TextField("Añade una descripción para los miembros...", text: $viewModel.newGroupDescription)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Película inicial
                VStack(alignment: .leading, spacing: 6) {
                    Text("PRIMERA PELÍCULA A DEBATIR (OPCIONAL)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    
                    TextField("Ej: Dune: Parte Dos, El Padrino...", text: $viewModel.newGroupMovieTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Tarjeta de Enlace de Invitación Generado
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        Text("ENLACE DE INVITACIÓN DIRECTO")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                    }
                    
                    Text("Cualquiera que tenga este enlace o código podrá unirse al grupo de chat:")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.generatedInviteLink)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("Código: \(viewModel.generatedInviteCode)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.copyToClipboard(viewModel.generatedInviteLink)
                            viewModel.showToast("¡Enlace copiado al portapapeles!")
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Copiar")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.Colors.WhatsApp.accentGreen)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(14)
                .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.WhatsApp.accentGreen.opacity(0.4), lineWidth: 1)
                )
                
                // Resumen de Participantes Añadidos
                if !viewModel.selectedFriends.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PARTICIPANTES QUE SE AÑADIRÁN (\(viewModel.selectedFriends.count))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.selectedFriends) { friend in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(red: 42/255, green: 57/255, blue: 66/255))
                                            .frame(width: 22, height: 22)
                                            .overlay(
                                                Text(String(friend.displayName.prefix(1)))
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                        Text(friend.displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                
                // Botón Crear Grupo
                Button {
                    guard let user = currentUser else { return }
                    Task {
                        _ = await viewModel.createGroup(creator: user)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                        Text("Crear Cineclub")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.newGroupName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Theme.Colors.WhatsApp.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.top, 10)
            }
            .padding(16)
        }
    }
    
    // MARK: - Sheet para Unirse mediante Enlace o Código
    
    private var joinByLinkSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 11/255, green: 20/255, blue: 26/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Theme.Colors.WhatsApp.accentGreen.opacity(0.15))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            )
                        
                        Text("Unirse a un Cineclub")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        Text("Pega el enlace de invitación recibido o escribe el código del grupo para entrar al chat.")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    
                    // Campo de entrada
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            TextField("Ej: CINE-NOLAN o https://moviesocial.app/join/...", text: $viewModel.inviteLinkOrCodeInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            
                            #if os(iOS)
                            Button("Pegar") {
                                if let clip = UIPasteboard.general.string {
                                    viewModel.inviteLinkOrCodeInput = clip
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            #endif
                        }
                        .padding(12)
                        .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Sugerencias rápidas de grupos oficiales de prueba
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CINECLUBS DESTACADOS:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        
                        HStack(spacing: 8) {
                            Button("CINE-NOLAN") {
                                viewModel.inviteLinkOrCodeInput = "CINE-NOLAN"
                            }
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            .clipShape(Capsule())
                            
                            Button("CINE-CLASSIC") {
                                viewModel.inviteLinkOrCodeInput = "CINE-CLASSIC"
                            }
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            .clipShape(Capsule())
                            
                            Button("CINE-TERROR") {
                                viewModel.inviteLinkOrCodeInput = "CINE-TERROR"
                            }
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 32/255, green: 44/255, blue: 51/255))
                            .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // Botón para Unirse
                    Button {
                        guard let user = currentUser else { return }
                        Task {
                            _ = await viewModel.joinGroupByCode(user: user)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Unirme al Cineclub")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(viewModel.inviteLinkOrCodeInput.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Theme.Colors.WhatsApp.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(viewModel.inviteLinkOrCodeInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Unirse con enlace")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.isJoiningViaLink = false
                        viewModel.inviteLinkOrCodeInput = ""
                        viewModel.errorMessage = nil
                    }
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
            }
        }
    }
}
