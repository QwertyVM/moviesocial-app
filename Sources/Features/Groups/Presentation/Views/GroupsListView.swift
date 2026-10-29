import SwiftUI

public struct GroupsListView: View {
    @Bindable public var viewModel: GroupsViewModel
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    private let availableEmojis = ["🎬", "🍿", "🚀", "🎭", "🔪", "🎞️", "👽", "🏎️", "🌟"]
    
    public init(
        viewModel: GroupsViewModel,
        currentUser: User?,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onSelectMovie = onSelectMovie
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    ProgressView()
                        .tint(Theme.Colors.textPrimary)
                } else if viewModel.groups.isEmpty {
                    emptyGroupsView
                } else {
                    groupsContentList
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CINECLUBS Y GRUPOS")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isCreatingGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.friendsAccent)
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isCreatingGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.friendsAccent)
                    }
                }
                #endif
            }
            .sheet(isPresented: $viewModel.isCreatingGroup) {
                createGroupSheet
            }
            .task {
                if viewModel.groups.isEmpty {
                    await viewModel.loadGroups()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var groupsContentList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Banner Explicativo
                HStack(spacing: 12) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.friendsAccent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tus Grupos de Cine")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("Reúnanse con amigos para acordar qué ver, votar y comentar cada estreno.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                
                // Lista de Tarjetas de Grupo
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.groups) { group in
                        NavigationLink {
                            GroupDetailView(
                                viewModel: viewModel,
                                group: group,
                                currentUser: currentUser,
                                onSelectMovie: onSelectMovie
                            )
                        } label: {
                            groupCard(group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.m)
        }
        .refreshable {
            await viewModel.loadGroups()
        }
    }
    
    private func groupCard(_ group: MovieGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Emoji Icon
                Text(group.iconEmoji)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Por \(group.creatorName) • \(group.totalMembersCount) miembros")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            
            if !group.description.isEmpty {
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Divider()
                .background(Theme.Colors.border.opacity(0.7))
            
            // Footer: Película actual o debate
            HStack {
                if let movie = group.currentMovieTitle {
                    HStack(spacing: 5) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.friendsAccent)
                        Text(movie)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                } else {
                    Text("Sin película asignada aún")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("\(group.messagesCount) mensajes")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
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
    
    private var emptyGroupsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.textTertiary)
            Text("Aún no tienes cineclubs o grupos")
                .font(.subheadline.bold())
                .foregroundColor(Theme.Colors.textPrimary)
            Text("Crea un grupo para juntarte con tus amigos y compartir películas.")
                .font(.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Crear mi primer grupo") {
                viewModel.isCreatingGroup = true
            }
            .font(.caption.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.Colors.friendsAccent)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .padding(.top, 4)
        }
        .padding(24)
    }
    
    private var createGroupSheet: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Selector de Emoji
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ICONO DEL GRUPO")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(availableEmojis, id: \.self) { emoji in
                                        Button {
                                            viewModel.selectedEmoji = emoji
                                        } label: {
                                            Text(emoji)
                                                .font(.system(size: 28))
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    viewModel.selectedEmoji == emoji
                                                        ? Theme.Colors.friendsAccent.opacity(0.3)
                                                        : Theme.Colors.surfaceElevated
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                                                        .stroke(
                                                            viewModel.selectedEmoji == emoji
                                                                ? Theme.Colors.friendsAccent
                                                                : Theme.Colors.border,
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Nombre
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOMBRE DEL CINECLUB")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            TextField("Ej: Amantes del Cine Negro", text: $viewModel.newGroupName)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(12)
                                .background(Theme.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                        }
                        
                        // Descripción
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPCIÓN O REGLAS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            TextField("Ej: Vemos una película cada fin de semana y la comentamos.", text: $viewModel.newGroupDescription)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(12)
                                .background(Theme.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                        }
                        
                        // Película inicial
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRIMERA PELÍCULA A VER (OPCIONAL)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            TextField("Ej: Interestelar", text: $viewModel.newGroupMovieTitle)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(12)
                                .background(Theme.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                        }
                        
                        // Botón de Creación
                        Button {
                            guard let user = currentUser else { return }
                            Task {
                                _ = await viewModel.createGroup(creator: user)
                            }
                        } label: {
                            Text("Crear Cineclub")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Theme.Colors.friendsAccent)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        }
                        .disabled(viewModel.newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.top, 10)
                    }
                    .padding(Theme.Spacing.m)
                }
            }
            .navigationTitle("Nuevo Cineclub")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.isCreatingGroup = false
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }
}

