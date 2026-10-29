import SwiftUI

public struct MovieDetailView: View {
    @Bindable public var viewModel: MovieDetailViewModel
    public let currentUser: User?
    
    public init(viewModel: MovieDetailViewModel, currentUser: User?) {
        self.viewModel = viewModel
        self.currentUser = currentUser
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // Hero Header con Póster y Datos Esenciales
                heroHeaderView
                
                // Badges Oficiales: Rotten Tomatoes, IMDb y Amigos
                VStack(alignment: .leading, spacing: 6) {
                    Text("PUNTUACIONES")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    RatingBadgesView(
                        ratings: viewModel.movie.ratings,
                        friendsAverage: viewModel.friendsAverageRating,
                        friendsCount: viewModel.friendReviews.count
                    )
                }
                .padding(.horizontal, Theme.Spacing.m)
                
                // Botón Calificar
                Button {
                    viewModel.isPresentingAddReview = true
                } label: {
                    HStack {
                        Image(systemName: "star.bubble")
                        Text("Calificar o dejar opinión")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Theme.Colors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                }
                .padding(.horizontal, Theme.Spacing.m)
                
                // Sinopsis
                VStack(alignment: .leading, spacing: 6) {
                    Text("SINOPSIS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(viewModel.movie.overview)
                        .font(.subheadline)
                        .lineSpacing(4)
                        .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
                }
                .padding(.horizontal, Theme.Spacing.m)
                
                Divider()
                    .background(Theme.Colors.border)
                    .padding(.horizontal, Theme.Spacing.m)
                
                // Sección Social: Opiniones y comentarios de Amigos
                friendsReviewsSection
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.movie.title.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .sheet(isPresented: $viewModel.isPresentingAddReview) {
            AddReviewSheetView(movie: viewModel.movie) { rating, comment in
                guard let user = currentUser else { return false }
                return await viewModel.submitReview(rating: rating, comment: comment, currentUser: user)
            }
        }
        .sheet(item: $viewModel.selectedReviewForComments) { review in
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
                    viewModel.selectedReviewForComments = nil
                }
            )
        }
        .task {
            await viewModel.loadDetails()
        }
    }
    
    // MARK: - Subviews
    
    private var heroHeaderView: some View {
        HStack(alignment: .top, spacing: 16) {
            // Póster
            if let poster = viewModel.movie.posterURL {
                AsyncImage(url: poster) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Theme.Colors.surfaceElevated)
                }
                .frame(width: 105, height: 155)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            
            // Ficha técnica
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.movie.title)
                    .font(.title3.bold())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                HStack(spacing: 8) {
                    Text("\(viewModel.movie.releaseYear)")
                    if let runtime = viewModel.movie.runtimeMinutes {
                        Text("•")
                        Text("\(runtime) min")
                    }
                }
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textTertiary)
                
                if !viewModel.movie.genres.isEmpty {
                    Text(viewModel.movie.genres.joined(separator: " / "))
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, Theme.Spacing.m)
    }
    
    private var friendsReviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("OPINIONES DE AMIGOS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                if let avg = viewModel.friendsAverageRating {
                    HStack(spacing: 4) {
                        Text("Media:")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textTertiary)
                        Text("👥 \(String(format: "%.1f", avg))")
                            .font(.caption.bold())
                            .foregroundColor(Theme.Colors.friendsAccent)
                    }
                }
            }
            
            if viewModel.friendReviews.isEmpty {
                VStack(spacing: 8) {
                    Text("Ningún amigo ha calificado esta película aún.")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("¡Sé el primero en compartir tu opinión!")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.friendReviews) { review in
                    reviewRow(review)
                }
            }
        }
    }
    
    private func reviewRow(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                // Avatar
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(review.userName.prefix(1)))
                            .font(.caption.bold())
                            .foregroundColor(Theme.Colors.textPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(review.userName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Spacer()
                
                // Rating
                HStack(spacing: 2) {
                    Text("★")
                        .foregroundColor(Theme.Colors.imdb)
                    Text(review.formattedRating)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
            }
            
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineSpacing(3)
            }
            
            // Latest comment preview if any
            if let latest = review.comments.last {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.Colors.friendsAccent)
                        .padding(.top, 2)
                    Text("\(latest.userName): \(latest.text)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .lineLimit(1)
                }
                .padding(6)
                .background(Theme.Colors.surfaceElevated.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
            
            // Bottom actions (Like & Comments)
            HStack(spacing: 16) {
                Button {
                    guard let user = currentUser else { return }
                    Task {
                        await viewModel.toggleLike(reviewId: review.id, user: user)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: review.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundColor(review.isLikedByMe ? .red : Theme.Colors.textTertiary)
                        Text("\(review.likesCount)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.selectedReviewForComments = review
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 12))
                            .foregroundColor(review.comments.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.friendsAccent)
                        Text(review.comments.isEmpty ? "Responder" : "\(review.comments.count) respuestas")
                            .font(.system(size: 11, weight: .medium))
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
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}
