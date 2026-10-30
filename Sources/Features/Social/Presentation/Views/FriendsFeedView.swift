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
                    // Selector segmentado minimalista
                    sectionPickerView
                    
                    if viewModel.selectedSection == .feed {
                        if viewModel.isLoading && viewModel.feedReviews.isEmpty {
                            ProgressView()
                                .tint(Theme.Colors.textTertiary)
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
                    Text(viewModel.selectedSection == .feed ? "ACTIVIDAD" : "AMIGOS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isAddingFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isAddingFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14))
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
        HStack(spacing: 0) {
            sectionPickerButton(title: "Actividad", section: .feed)
            sectionPickerButton(title: "Mis Amigos (\(viewModel.friends.count))", section: .friends)
        }
        .padding(2)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Theme.Colors.border, lineWidth: 0.8)
        )
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
    
    private func sectionPickerButton(title: String, section: SocialTabSection) -> some View {
        let isSelected = (viewModel.selectedSection == section)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSection = section
            }
        } label: {
            Text(title)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.Colors.surfaceElevated : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private var feedContentView: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Carrusel de Amigos Minimalista
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
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredReviews) { review in
                            feedItemView(review)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
        }
        .refreshable {
            await viewModel.loadSocialFeed()
        }
    }
    
    private var friendsCarouselView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AMIGOS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Spacer()
                
                Button {
                    viewModel.selectedSection = .friends
                } label: {
                    HStack(spacing: 3) {
                        Text("Ver listado (\(viewModel.friends.count))")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Botón directo para añadir amigo
                    Button {
                        viewModel.isAddingFriend = true
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Theme.Colors.surface)
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Theme.Colors.textPrimary)
                                )
                                .overlay(
                                    Circle().stroke(Theme.Colors.border, lineWidth: 0.8)
                                )
                            
                            Text("Añadir")
                                .font(.system(size: 10.5))
                                .foregroundColor(Theme.Colors.textTertiary)
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
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.Colors.surfaceElevated)
                                    .frame(width: 46, height: 46)
                                    .overlay(
                                        Text(String(friend.displayName.prefix(1)))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isSelected ? Theme.Colors.friendsAccent : Theme.Colors.border,
                                                lineWidth: isSelected ? 2 : 0.8
                                            )
                                    )
                                
                                Text(friend.displayName.components(separatedBy: " ").first ?? friend.displayName)
                                    .font(.system(size: 10.5, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? Theme.Colors.friendsAccent : Theme.Colors.textSecondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 54)
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
                .padding(.vertical, 2)
            }
        }
    }
    
    private func activeFriendFilterBanner(_ friend: Friend) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.Colors.friendsAccent.opacity(0.15))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(String(friend.displayName.prefix(1)))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.Colors.friendsAccent)
                )
            
            Text("Filtrando por **\(friend.displayName)**")
                .font(.system(size: 11.5))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
            
            Button {
                viewModel.clearFriendFilter()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border, lineWidth: 0.8)
        )
    }
    
    private var emptyFilteredFeedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "film")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.top, 16)
            
            Text("No hay reseñas con este filtro")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
            
            if viewModel.filterFriendId != nil {
                Button("Mostrar todas las reseñas") {
                    viewModel.clearFriendFilter()
                }
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(Theme.Colors.friendsAccent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var filterSelectorView: some View {
        HStack(spacing: 6) {
            ForEach(SocialFeedFilter.allCases, id: \.self) { filter in
                let isSelected = viewModel.selectedFilter == filter
                Button {
                    viewModel.selectedFilter = filter
                } label: {
                    HStack(spacing: 4) {
                        Text(filter.rawValue)
                            .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                        if filter == .withComments {
                            let count = viewModel.feedReviews.filter { !$0.comments.isEmpty }.count
                            Text("(\(count))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isSelected ? .white : Theme.Colors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isSelected ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
                    .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isSelected ? Theme.Colors.borderFocused : Theme.Colors.border, lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    private func feedItemView(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Friend Header
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(review.userName.prefix(1)))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(review.userName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10.5))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Spacer()
                
                // Rating Pill Minimalista
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Theme.Colors.imdb)
                    Text(review.formattedRating)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Theme.Colors.border, lineWidth: 0.8)
                )
            }
            
            // Comment
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(size: 13))
                    .lineSpacing(2.5)
                    .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
            }
            
            // Histórico de primera reseña si fue editada tras > 3 meses
            if review.hasHistoricalRecord {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedHistoryReviewIds.contains(review.id) {
                                expandedHistoryReviewIds.remove(review.id)
                            } else {
                                expandedHistoryReviewIds.insert(review.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 9))
                            Text(expandedHistoryReviewIds.contains(review.id) ? "Ocultar histórico" : "Ver primera reseña")
                                .font(.system(size: 10.5, weight: .medium))
                            Image(systemName: expandedHistoryReviewIds.contains(review.id) ? "chevron.up" : "chevron.down")
                                .font(.system(size: 7))
                        }
                        .foregroundColor(Theme.Colors.friendsAccent)
                    }
                    .buttonStyle(.plain)
                    
                    if expandedHistoryReviewIds.contains(review.id) {
                        ForEach(review.history) { hist in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("PRIMERA RESEÑA")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Theme.Colors.textTertiary)
                                    Spacer()
                                    Text("★ \(hist.formattedRating)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.Colors.imdb)
                                }
                                if !hist.comment.isEmpty {
                                    Text("\"\(hist.comment)\"")
                                        .font(.system(size: 10.5))
                                        .italic()
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Colors.surfaceElevated.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            
            // Movie link card
            Button {
                onSelectMovie(review.movieId)
            } label: {
                HStack(spacing: 10) {
                    if let poster = review.moviePosterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Theme.Colors.surfaceElevated)
                        }
                        .frame(width: 32, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(review.movieTitle)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        if let year = review.movieReleaseYear {
                            Text("\(year)")
                                .font(.system(size: 10.5))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(6)
                .background(Theme.Colors.surfaceElevated.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            // Action bar: Me gusta y Comentarios
            HStack(spacing: 14) {
                Button {
                    guard let user = currentUser else { return }
                    Task {
                        await viewModel.toggleLike(reviewId: review.id, user: user)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: review.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundColor(review.isLikedByMe ? .red : Theme.Colors.textTertiary)
                        Text("\(review.likesCount)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.activeCommentReview = review
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textTertiary)
                        Text(review.comments.isEmpty ? "Comentar" : "\(review.comments.count)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.Colors.border, lineWidth: 0.8)
        )
    }
    
    private var emptyFeedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.top, 40)
            
            Text("Aún no hay actividad")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Conecta con amigos para ver sus valoraciones y debatir de cine.")
                .font(.system(size: 12.5))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                viewModel.isAddingFriend = true
            } label: {
                Text("Añadir amigo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Theme.Colors.textPrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
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
                
                VStack(spacing: 14) {
                    Text("Conecta con tus amigos para ver sus notas y opiniones sobre cualquier película.")
                        .font(.system(size: 13))
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
                    .padding(10)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.Colors.border, lineWidth: 0.8)
                    )
                    .padding(.horizontal)
                    
                    Button {
                        Task {
                            await viewModel.addFriend()
                        }
                    } label: {
                        Text("Añadir Amigo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.Colors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
