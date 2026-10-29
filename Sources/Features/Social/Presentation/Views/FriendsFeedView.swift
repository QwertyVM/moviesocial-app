import SwiftUI

public struct FriendsFeedView: View {
    @Bindable public var viewModel: SocialViewModel
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    public init(
        viewModel: SocialViewModel,
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
                
                if viewModel.isLoading && viewModel.feedReviews.isEmpty {
                    ProgressView()
                        .tint(Theme.Colors.textPrimary)
                } else if viewModel.feedReviews.isEmpty {
                    emptyFeedView
                } else {
                    feedContentView
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ACTIVIDAD DE AMIGOS")
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
            .task {
                if viewModel.feedReviews.isEmpty {
                    await viewModel.loadSocialFeed()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var feedContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filtro rápido: Todas las reseñas o solo con comentarios
                filterSelectorView
                
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredReviews) { review in
                        feedItemView(review)
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
        VStack(spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 36))
                .foregroundColor(Theme.Colors.textTertiary)
            Text("Aún no hay actividad de amigos")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
            Button("Añadir un amigo") {
                viewModel.isAddingFriend = true
            }
            .font(.caption.bold())
            .foregroundColor(Theme.Colors.friendsAccent)
        }
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
