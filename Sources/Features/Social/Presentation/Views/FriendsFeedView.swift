import SwiftUI

public struct FriendsFeedView: View {
    @Bindable public var viewModel: SocialViewModel
    public let currentUser: User?
    public let onOpenChat: ((Friend) -> Void)?
    public let onSelectMovie: (String) -> Void
    
    @State private var expandedHistoryReviewIds: Set<String> = []
    
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
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Selector segmentado: Actividad vs Mis Amigos
                    sectionPickerView
                    
                    if viewModel.selectedSection == .feed {
                        if viewModel.isLoading && viewModel.feedReviews.isEmpty {
                            ProgressView()
                                .tint(Theme.Colors.textPrimary)
                                .frame(maxHeight: .infinity)
                        } else if viewModel.feedReviews.isEmpty {
                            emptyFeedView
                        } else {
                            feedContentView
                        }
                    } else {
                        FriendsListView(
                            viewModel: viewModel,
                            currentUser: currentUser,
                            onOpenChat: onOpenChat,
                            onSelectMovie: onSelectMovie
                        )
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.selectedSection == .feed ? "ACTIVIDAD DE AMIGOS" : "LISTADO DE AMIGOS")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isAddingFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isAddingFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
                #endif
            }
            .sheet(isPresented: $viewModel.isAddingFriend) {
                addFriendSheet
            }
            .sheet(item: $viewModel.activeCommentReview) { review in
                ReviewCommentsSheetView(
                    review: review,
                    currentUser: currentUser,
                    onAddComment: { text in
                        guard let user = currentUser else { return false }
                        return await viewModel.addComment(to: review.id, text: text, user: user)
                    },
                    onToggleLike: {
                        guard let user = currentUser else { return }
                        await viewModel.toggleLike(reviewId: review.id, user: user)
                    },
                    onDismiss: {
                        viewModel.activeCommentReview = nil
                    }
                )
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
            .task {
                if viewModel.feedReviews.isEmpty {
                    await viewModel.loadSocialFeed()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var sectionPickerView: some View {
        Picker("Sección", selection: $viewModel.selectedSection) {
            Text("Actividad").tag(SocialTabSection.feed)
            Text("Mis Amigos (\(viewModel.friends.count))").tag(SocialTabSection.friends)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private var feedContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Carrusel de Amigos
                friendsCarouselView
                
                // Banner si se está filtrando por un amigo específico
                if let activeFriend = viewModel.activeFilteredFriend {
                    activeFriendFilterBanner(activeFriend)
                }
                
                // Filtro rápido: Todas las reseñas o solo con comentarios
                filterSelectorView
                
                if viewModel.filteredReviews.isEmpty {
                    emptyFilteredFeedView
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredReviews) { review in
                            feedItemView(review)
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
    }
    
    private var friendsCarouselView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AMIGOS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Spacer()
                
                Button {
                    viewModel.selectedSection = .friends
                } label: {
                    HStack(spacing: 3) {
                        Text("Ver listado completo (\(viewModel.friends.count))")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.friendsAccent)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Botón directo para añadir amigo
                    Button {
                        viewModel.isAddingFriend = true
                    } label: {
                        VStack(spacing: 5) {
                            Circle()
                                .strokeBorder(Theme.Colors.border, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .background(Circle().fill(Theme.Colors.surface))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.Colors.textPrimary)
                                )
                            
                            Text("Añadir")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Círculos de amigos
                    ForEach(viewModel.friends) { friend in
                        let isSelected = viewModel.filterFriendId == friend.id
                        Button {
                            if isSelected {
                                viewModel.clearFriendFilter()
                            } else {
                                viewModel.filterFriendId = friend.id
                            }
                        } label: {
                            VStack(spacing: 5) {
                                Circle()
                                    .fill(Theme.Colors.surfaceElevated)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(friend.displayName.prefix(1)))
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isSelected ? Theme.Colors.friendsAccent : Theme.Colors.border,
                                                lineWidth: isSelected ? 2.5 : 1
                                            )
                                    )
                                
                                Text(friend.displayName.components(separatedBy: " ").first ?? friend.displayName)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? Theme.Colors.friendsAccent : Theme.Colors.textSecondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 56)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                viewModel.selectedFriendForDetail = friend
                            } label: {
                                Label("Ver perfil de \(friend.displayName)", systemImage: "person.crop.circle")
                            }
                            
                            Button {
                                if isSelected {
                                    viewModel.clearFriendFilter()
                                } else {
                                    viewModel.filterFriendId = friend.id
                                }
                            } label: {
                                Label(
                                    isSelected ? "Mostrar todas las reseñas" : "Filtrar feed por este amigo",
                                    systemImage: "line.3.horizontal.decrease.circle"
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func activeFriendFilterBanner(_ friend: Friend) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.Colors.friendsAccent.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(friend.displayName.prefix(1)))
                        .font(.caption.bold())
                        .foregroundColor(Theme.Colors.friendsAccent)
                )
            
            Text("Viendo reseñas de **\(friend.displayName)**")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
            
            Button {
                viewModel.clearFriendFilter()
            } label: {
                HStack(spacing: 4) {
                    Text("Ver todas")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.Colors.friendsAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.small)
                .stroke(Theme.Colors.friendsAccent.opacity(0.35), lineWidth: 1)
        )
    }
    
    private var emptyFilteredFeedView: some View {
        VStack(spacing: 10) {
            Image(systemName: "film.stack")
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.top, 20)
            
            Text("No hay reseñas con este filtro")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
            
            if viewModel.filterFriendId != nil {
                Button("Mostrar todas las reseñas") {
                    viewModel.clearFriendFilter()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.friendsAccent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var filterSelectorView: some View {
        HStack(spacing: 8) {
            ForEach(SocialFeedFilter.allCases, id: \.self) { filter in
                Button {
                    viewModel.selectedFilter = filter
                } label: {
                    HStack(spacing: 6) {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                        if filter == .withComments {
                            let count = viewModel.feedReviews.filter { !$0.comments.isEmpty }.count
                            Text("(\(count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(viewModel.selectedFilter == filter ? Theme.Colors.background : Theme.Colors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.selectedFilter == filter
                            ? Theme.Colors.textPrimary
                            : Theme.Colors.surfaceElevated
                    )
                    .foregroundColor(
                        viewModel.selectedFilter == filter
                            ? Theme.Colors.background
                            : Theme.Colors.textSecondary
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    private func feedItemView(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Friend Header
            HStack(spacing: 10) {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(review.userName.prefix(1)))
                            .font(.caption.bold())
                            .foregroundColor(Theme.Colors.textPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Spacer()
                
                // Rating Pill
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
            
            // Comment
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .lineSpacing(3)
                    .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
            }
            
            // Histórico de primera reseña si fue editada tras > 3 meses
            if review.hasHistoricalRecord {
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedHistoryReviewIds.contains(review.id) {
                                expandedHistoryReviewIds.remove(review.id)
                            } else {
                                expandedHistoryReviewIds.insert(review.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 10))
                            Text(expandedHistoryReviewIds.contains(review.id) ? "Ocultar histórico" : "Ver primera reseña (Histórico)")
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: expandedHistoryReviewIds.contains(review.id) ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(Theme.Colors.friendsAccent)
                    }
                    .buttonStyle(.plain)
                    
                    if expandedHistoryReviewIds.contains(review.id) {
                        ForEach(review.history) { hist in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text("PRIMERA RESEÑA (HISTÓRICO)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.Colors.friendsAccent)
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Text("★")
                                            .foregroundColor(Theme.Colors.imdb)
                                        Text(hist.formattedRating)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                    }
                                }
                                if !hist.comment.isEmpty {
                                    Text("\"\(hist.comment)\"")
                                        .font(.system(size: 11))
                                        .italic()
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                Text("Publicada el \(hist.createdAt.formatted(date: .abbreviated, time: .omitted)) • Archivada el \(hist.archivedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.system(size: 9))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Colors.surfaceElevated.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.small)
                                    .stroke(Theme.Colors.border, lineWidth: 0.5)
                            )
                        }
                    }
                }
                .padding(.top, 2)
            }
            
            // Movie link card
            Button {
                onSelectMovie(review.movieId)
            } label: {
                HStack(spacing: 12) {
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
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(8)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
            .buttonStyle(.plain)
            
            // Mini Preview of latest friend comment (si existe)
            if let latestComment = review.comments.last {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.friendsAccent)
                        Text(latestComment.userName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("comentó:")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    Text(latestComment.text)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }
                .padding(10)
                .background(Theme.Colors.surfaceElevated.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
            
            // Action bar: Me gusta y Comentarios
            HStack(spacing: 16) {
                // Like Button
                Button {
                    guard let user = currentUser else { return }
                    Task {
                        await viewModel.toggleLike(reviewId: review.id, user: user)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: review.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(review.isLikedByMe ? .red : Theme.Colors.textTertiary)
                        Text("\(review.likesCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                // Comments Button
                Button {
                    viewModel.activeCommentReview = review
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 13))
                            .foregroundColor(review.comments.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.friendsAccent)
                        Text(review.comments.isEmpty ? "Comentar" : "\(review.comments.count) comentarios")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var emptyFeedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.top, 40)
            
            Text("Aún no hay actividad de amigos")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Conecta con tus amigos o revisa tu lista para empezar a ver sus valoraciones.")
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            HStack(spacing: 12) {
                Button {
                    viewModel.isAddingFriend = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Añadir amigo")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.friendsAccent)
                    .clipShape(Capsule())
                }
                
                Button {
                    viewModel.selectedSection = .friends
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                        Text("Ver mis amigos (\(viewModel.friends.count))")
                    }
                    .font(.caption.bold())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var addFriendSheet: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Conecta con tus amigos para ver sus notas y opiniones sobre cualquier película.")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    HStack {
                        #if os(iOS)
                        TextField("Nombre de usuario (ej. @cinefilo)", text: $viewModel.newFriendUsername)
                            .textFieldStyle(.plain)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        #else
                        TextField("Nombre de usuario (ej. @cinefilo)", text: $viewModel.newFriendUsername)
                            .textFieldStyle(.plain)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .autocorrectionDisabled()
                        #endif
                    }
                    .padding(12)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    Button {
                        Task {
                            await viewModel.addFriend()
                        }
                    } label: {
                        Text("Añadir Amigo")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Theme.Colors.friendsAccent)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.newFriendUsername.isEmpty)
                    
                    Spacer()
                }
            }
            .navigationTitle("Añadir Amigo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        viewModel.isAddingFriend = false
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }
}
