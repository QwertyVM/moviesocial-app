import SwiftUI

public struct ReviewCommentsSheetView: View {
    public let review: Review
    public let currentUser: User?
    public let onAddComment: (String) async -> Bool
    public let onToggleLike: () async -> Void
    public let onDismiss: () -> Void
    
    @State private var commentText: String = ""
    @State private var isSubmitting: Bool = false
    
    public init(
        review: Review,
        currentUser: User?,
        onAddComment: @escaping (String) async -> Bool,
        onToggleLike: @escaping () async -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.review = review
        self.currentUser = currentUser
        self.onAddComment = onAddComment
        self.onToggleLike = onToggleLike
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Encabezado de la Reseña original
                            originalReviewHeader
                            
                            Divider()
                                .background(Theme.Colors.border)
                            
                            // Lista de comentarios
                            commentsSection
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.m)
                    }
                    
                    // Barra de entrada inferior
                    commentInputField
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("COMENTARIOS (\(review.comments.count))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
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
        }
    }
    
    // MARK: - Subviews
    
    private var originalReviewHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Text(String(review.userName.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    HStack(spacing: 6) {
                        Text(review.movieTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.friendsAccent)
                        Text("•")
                            .foregroundColor(Theme.Colors.textTertiary)
                        Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text("★")
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
            
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary.opacity(0.95))
                    .lineSpacing(3)
            }
            
            // Acciones: Me Gusta
            HStack(spacing: 16) {
                Button {
                    Task {
                        await onToggleLike()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: review.isLikedByMe ? "heart.fill" : "heart")
                            .foregroundColor(review.isLikedByMe ? .red : Theme.Colors.textSecondary)
                        Text("\(review.likesCount) me gusta")
                            .font(.caption.weight(.medium))
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
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RESPUESTAS DE AMIGOS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.Colors.textSecondary)
            
            if review.comments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("Aún no hay comentarios en esta reseña")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("¡Sé el primero en debatir o preguntarle qué le pareció!")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(review.comments) { comment in
                    commentRow(comment)
                }
            }
        }
    }
    
    private func commentRow(_ comment: ReviewComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Theme.Colors.surfaceElevated)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(comment.userName.prefix(1)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(comment.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Text(comment.text)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
                    .lineSpacing(2)
            }
            .padding(10)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small)
                    .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
            )
        }
    }
    
    private var commentInputField: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.Colors.border)
            
            HStack(spacing: 10) {
                #if os(iOS)
                TextField("Escribe un comentario a tu amigo...", text: $commentText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .submitLabel(.send)
                    .onSubmit {
                        submitComment()
                    }
                #else
                TextField("Escribe un comentario a tu amigo...", text: $commentText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .onSubmit {
                        submitComment()
                    }
                #endif
                
                Button {
                    submitComment()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(commentText.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.Colors.textTertiary : Theme.Colors.friendsAccent)
                    }
                }
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, 12)
            .background(Theme.Colors.surface)
        }
    }
    
    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSubmitting else { return }
        
        isSubmitting = true
        Task {
            let success = await onAddComment(text)
            if success {
                commentText = ""
            }
            isSubmitting = false
        }
    }
}

