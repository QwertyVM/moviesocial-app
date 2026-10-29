import SwiftUI

public struct GroupDetailView: View {
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
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Cabecera del Grupo
                            groupHeaderView
                            
                            // Película de la semana / Quedada
                            if let movieTitle = group.currentMovieTitle {
                                featuredMovieCard(title: movieTitle)
                            }
                            
                            // Miembros
                            membersSection
                            
                            Divider()
                                .background(Theme.Colors.border)
                            
                            // Chat / Debate
                            debateSection
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.m)
                    }
                    .onChange(of: viewModel.currentGroupMessages.count) { _, _ in
                        if let last = viewModel.currentGroupMessages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Barra de mensaje inferior
                messageInputBar
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(group.iconEmoji)
                    Text(group.name.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
            }
        }
        .task {
            await viewModel.loadMessages(for: group.id)
        }
    }
    
    // MARK: - Subviews
    
    private var groupHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(group.iconEmoji)
                    .font(.system(size: 38))
                    .frame(width: 56, height: 56)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.title3.bold())
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Creado por \(group.creatorName)")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            
            if !group.description.isEmpty {
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private func featuredMovieCard(title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PELÍCULA EN DISCUSIÓN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.Colors.friendsAccent)
            
            HStack(spacing: 12) {
                if let poster = group.currentMoviePosterURL {
                    AsyncImage(url: poster) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Theme.Colors.surfaceElevated)
                    }
                    .frame(width: 44, height: 66)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .fill(Theme.Colors.surfaceElevated)
                        .frame(width: 44, height: 66)
                        .overlay(
                            Image(systemName: "film")
                                .foregroundColor(Theme.Colors.textTertiary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if let year = group.currentMovieYear {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    
                    Text("Seleccionada por el grupo para ver y debatir")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                if let movieId = group.currentMovieId {
                    Button {
                        onSelectMovie(movieId)
                    } label: {
                        Text("Ver")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.Colors.surfaceElevated)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.friendsAccent.opacity(0.4), lineWidth: 1)
        )
    }
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MIEMBROS (\(group.totalMembersCount))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                if let user = currentUser, !group.members.contains(where: { $0.id == user.id }) && group.creatorId != user.id {
                    Button {
                        Task {
                            await viewModel.joinGroup(groupId: group.id, user: user)
                        }
                    } label: {
                        Text("+ Unirme al grupo")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.Colors.friendsAccent)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Creador
                    memberChip(name: group.creatorName, isCreator: true)
                    
                    // Miembros
                    ForEach(group.members) { member in
                        memberChip(name: member.displayName, isCreator: false)
                    }
                }
            }
        }
    }
    
    private func memberChip(name: String, isCreator: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.Colors.surfaceElevated)
                .frame(width: 22, height: 22)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                )
            
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            if isCreator {
                Text("Admin")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Theme.Colors.friendsAccent.opacity(0.3))
                    .foregroundColor(Theme.Colors.friendsAccent)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var debateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SALA DE DEBATE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.Colors.textSecondary)
            
            if viewModel.currentGroupMessages.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("El debate aún no ha comenzado.")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("¡Envía un mensaje para coordinar la quedada o comentar la película!")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.currentGroupMessages) { msg in
                    messageBubble(msg)
                        .id(msg.id)
                }
            }
        }
    }
    
    private func messageBubble(_ msg: GroupMessage) -> some View {
        let isMe = msg.userId == currentUser?.id
        
        return HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 40) }
            
            if !isMe {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(msg.userName.prefix(1)))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                    )
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(msg.userName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.Colors.friendsAccent)
                }
                
                Text(msg.text)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineSpacing(2)
                
                Text(msg.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isMe ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(isMe ? Theme.Colors.friendsAccent.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
            )
            
            if !isMe { Spacer(minLength: 40) }
        }
    }
    
    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.Colors.border)
            
            HStack(spacing: 10) {
                #if os(iOS)
                TextField("Escribe al grupo...", text: $viewModel.newMessageText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }
                #else
                TextField("Escribe al grupo...", text: $viewModel.newMessageText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .onSubmit {
                        sendMessage()
                    }
                #endif
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(viewModel.newMessageText.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.Colors.textTertiary : Theme.Colors.friendsAccent)
                }
                .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, 12)
            .background(Theme.Colors.surface)
        }
    }
    
    private func sendMessage() {
        guard let user = currentUser else { return }
        Task {
            _ = await viewModel.sendMessage(user: user)
        }
    }
}

