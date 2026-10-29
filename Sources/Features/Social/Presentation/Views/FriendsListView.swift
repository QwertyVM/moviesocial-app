import SwiftUI

/// Vista dedicada para consultar, buscar y gestionar el listado completo de amigos
public struct FriendsListView: View {
    @Bindable public var viewModel: SocialViewModel
    public let currentUser: User?
    public let onOpenChat: ((Friend) -> Void)?
    public let onSelectMovie: (String) -> Void
    
    @State private var friendToRemove: Friend? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    public init(
        viewModel: SocialViewModel,
        currentUser: User?,
        onOpenChat: ((Friend) -> Void)? = nil,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onOpenChat = onOpenChat
        self.onSelectMovie = onSelectMovie
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                // Buscador de amigos
                searchBar
                
                // Resumen de estadísticas sociales
                statsSummaryView
                
                // Botón rápido para añadir amigos
                addFriendBanner
                
                // Cabecera de la sección
                HStack {
                    Text("TUS AMIGOS (\(viewModel.filteredFriends.count))")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if !viewModel.friendSearchText.isEmpty {
                        Button("Limpiar") {
                            viewModel.friendSearchText = ""
                        }
                        .font(.caption)
                        .foregroundColor(Theme.Colors.friendsAccent)
                    }
                }
                .padding(.top, Theme.Spacing.xs)
                
                // Listado o estados vacíos
                if viewModel.friends.isEmpty {
                    emptyFriendsView
                } else if viewModel.filteredFriends.isEmpty {
                    emptySearchResultsView
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredFriends) { friend in
                            friendCard(friend)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.m)
        }
        .refreshable {
            await viewModel.loadSocialFeed()
        }
        .sheet(item: $viewModel.selectedFriendForDetail) { friend in
            FriendDetailSheetView(
                friend: friend,
                viewModel: viewModel,
                currentUser: currentUser,
                onOpenChat: onOpenChat,
                onSelectMovie: onSelectMovie,
                onDismiss: {
                    viewModel.selectedFriendForDetail = nil
                }
            )
        }
        .confirmationDialog(
            "¿Eliminar a \(friendToRemove?.displayName ?? "este amigo")?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar de mis amigos", role: .destructive) {
                if let friend = friendToRemove {
                    Task {
                        await viewModel.removeFriend(friendId: friend.id)
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Dejarás de ver su actividad y opiniones en tu feed.")
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.textTertiary)
                .font(.system(size: 14))
            
            TextField("Buscar amigos por nombre o @usuario...", text: $viewModel.friendSearchText)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textPrimary)
                .autocorrectionDisabled()
            
            if !viewModel.friendSearchText.isEmpty {
                Button {
                    viewModel.friendSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.textTertiary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var statsSummaryView: some View {
        HStack(spacing: 8) {
            statItem(
                icon: "person.2.fill",
                title: "AMIGOS",
                value: "\(viewModel.friends.count)"
            )
            
            statItem(
                icon: "circle.fill",
                title: "EN LÍNEA",
                value: "\(viewModel.onlineFriendsCount)",
                tint: .green
            )
            
            statItem(
                icon: "sparkles",
                title: "GUSTOS",
                value: "\(viewModel.totalMutualMoviesCount)"
            )
            
            statItem(
                icon: "star.bubble.fill",
                title: "RESEÑAS",
                value: "\(viewModel.feedReviews.count)"
            )
        }
    }
    
    private func statItem(icon: String, title: String, value: String, tint: Color = Theme.Colors.friendsAccent) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var addFriendBanner: some View {
        Button {
            viewModel.isAddingFriend = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.Colors.friendsAccent.opacity(0.18))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.friendsAccent)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Añadir un amigo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("Encuentra amigos por su @usuario para compartir cine")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(12)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func friendCard(_ friend: Friend) -> some View {
        Button {
            viewModel.selectedFriendForDetail = friend
        } label: {
            HStack(spacing: 12) {
                // Avatar con estado de conexión
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Theme.Colors.surfaceElevated)
                        .frame(width: 46, height: 46)
                        .overlay(
                            Text(String(friend.displayName.prefix(1)))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Theme.Colors.textPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    
                    if friend.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.surface, lineWidth: 2)
                            )
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(friend.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        if friend.isMutual {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.friendsAccent)
                        }
                    }
                    
                    Text(friend.username)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    // Badges
                    HStack(spacing: 6) {
                        if friend.isOnline {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("En línea")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(Color.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9))
                            Text("\(friend.mutualMoviesCount) gustos compartidos")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.friendsAccent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Theme.Colors.friendsAccent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(12)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                viewModel.selectedFriendForDetail = friend
            } label: {
                Label("Ver perfil y reseñas", systemImage: "person.crop.circle")
            }
            
            Button {
                viewModel.filterFriendId = friend.id
                viewModel.selectedSection = .feed
            } label: {
                Label("Filtrar feed por este amigo", systemImage: "line.3.horizontal.decrease.circle")
            }
            
            Divider()
            
            Button(role: .destructive) {
                friendToRemove = friend
                showDeleteConfirmation = true
            } label: {
                Label("Eliminar de amigos", systemImage: "person.badge.minus")
            }
        }
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.and.arrow.left.and.arrow.right")
                .font(.system(size: 36))
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.top, 30)
            
            Text("Sin resultados para \"\(viewModel.friendSearchText)\"")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Revisa la ortografía o intenta buscar por su nombre de usuario.")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button("Limpiar búsqueda") {
                viewModel.friendSearchText = ""
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Theme.Colors.friendsAccent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.top, 30)
            
            Text("Aún no tienes amigos agregados")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Conecta con tus amigos cinéfilos para compartir opiniones, ver qué puntuación le dan a cada película y comparar gustos.")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                viewModel.isAddingFriend = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                    Text("Añadir tu primer amigo")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.Colors.friendsAccent)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Friend Detail Sheet View

/// Vista detallada del perfil de un amigo, con sus estadísticas y todas sus reseñas
public struct FriendDetailSheetView: View {
    public let friend: Friend
    @Bindable public var viewModel: SocialViewModel
    public let currentUser: User?
    public let onOpenChat: ((Friend) -> Void)?
    public let onSelectMovie: (String) -> Void
    public let onDismiss: () -> Void
    
    @State private var showDeleteConfirmation: Bool = false
    
    public init(
        friend: Friend,
        viewModel: SocialViewModel,
        currentUser: User?,
        onOpenChat: ((Friend) -> Void)? = nil,
        onSelectMovie: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.friend = friend
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onOpenChat = onOpenChat
        self.onSelectMovie = onSelectMovie
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Header del Amigo
                        friendHeaderView
                        
                        // Acciones rápidas
                        quickActionsView
                        
                        Divider()
                            .background(Theme.Colors.border)
                        
                        // Reseñas del Amigo
                        friendReviewsSection
                        
                        // Botón para eliminar amigo
                        deleteFriendButton
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PERFIL DE AMIGO")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        onDismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .confirmationDialog(
                "¿Eliminar a \(friend.displayName)?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar de mis amigos", role: .destructive) {
                    Task {
                        await viewModel.removeFriend(friendId: friend.id)
                        onDismiss()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Dejarás de ver sus valoraciones en tu feed.")
            }
        }
    }
    
    private var friendHeaderView: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 76, height: 76)
                    .overlay(
                        Text(String(friend.displayName.prefix(1)))
                            .font(.title.bold())
                            .foregroundColor(Theme.Colors.textPrimary)
                    )
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.border, lineWidth: 1.5)
                    )
                
                if friend.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.background, lineWidth: 3)
                        )
                }
            }
            
            VStack(spacing: 4) {
                Text(friend.displayName)
                    .font(.title3.bold())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(friend.username)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                HStack(spacing: 8) {
                    if friend.isOnline {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("En línea")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("\(friend.mutualMoviesCount) gustos compartidos (> 3★)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.friendsAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.friendsAccent.opacity(0.12))
                    .clipShape(Capsule())
                    
                    if friend.isMutual {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                            Text("Amigos mutuos")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, Theme.Spacing.s)
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 10) {
            if let onOpenChat = onOpenChat {
                Button {
                    onDismiss()
                    onOpenChat(friend)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 13))
                        Text("Abrir Chat 1 a 1")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Theme.Colors.WhatsApp.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                }
                .buttonStyle(.plain)
            }
            
            Button {
                viewModel.filterFriendId = friend.id
                viewModel.selectedSection = .feed
                onDismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 13))
                    Text("Ver actividad en el feed")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Theme.Colors.friendsAccent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var friendReviewsSection: some View {
        let reviews = viewModel.reviewsForFriend(friendId: friend.id)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RESEÑAS (\(reviews.count))")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
            }
            
            if reviews.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("Aún no ha calificado películas")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("Cuando califique o reseñe una película, aparecerá aquí.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            } else {
                VStack(spacing: 12) {
                    ForEach(reviews) { review in
                        reviewCard(review)
                    }
                }
            }
        }
    }
    
    private func reviewCard(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Película Header
            Button {
                onDismiss()
                onSelectMovie(review.movieId)
            } label: {
                HStack(spacing: 10) {
                    if let poster = review.moviePosterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Theme.Colors.surfaceElevated)
                        }
                        .frame(width: 38, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(review.movieTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        if let year = review.movieReleaseYear {
                            Text("\(year)")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 3) {
                        Text("★")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.imdb)
                        Text(review.formattedRating)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
            
            // Comentario
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
            }
            
            // Footer con fecha y likes
            HStack {
                Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(review.isLikedByMe ? .red : Theme.Colors.textTertiary)
                        Text("\(review.likesCount)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                        Text("\(review.comments.count)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var deleteFriendButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "person.badge.minus")
                Text("Eliminar de mis amigos")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.red.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
        .padding(.top, Theme.Spacing.s)
    }
}
