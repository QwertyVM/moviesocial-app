import SwiftUI

/// Modal minimalista para registrar o editar calificación y opinión
public struct AddReviewSheetView: View {
    public let movie: Movie
    public let existingReview: Review?
    public let onSubmit: (Double, String) async -> Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var rating: Double
    @State private var comment: String
    @State private var isSubmitting: Bool = false
    
    public init(
        movie: Movie,
        existingReview: Review? = nil,
        onSubmit: @escaping (Double, String) async -> Bool
    ) {
        self.movie = movie
        self.existingReview = existingReview
        self._rating = State(initialValue: existingReview?.rating ?? 4.0)
        self._comment = State(initialValue: existingReview?.comment ?? "")
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.l) {
                    // Movie header info
                    HStack(spacing: 12) {
                        if let poster = movie.posterURL {
                            AsyncImage(url: poster) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Theme.Colors.surfaceElevated)
                            }
                            .frame(width: 44, height: 66)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(movie.title)
                                .font(.headline)
                                .foregroundColor(Theme.Colors.textPrimary)
                            Text("\(movie.releaseYear)")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, Theme.Spacing.m)
                    
                    // Aviso de política de edición / histórico
                    if let existing = existingReview {
                        let hasPassed3Months = Review.hasPassedMoreThanThreeMonths(from: existing.createdAt)
                        if hasPassed3Months {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(Theme.Colors.friendsAccent)
                                    Text("Han pasado más de 3 meses")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.Colors.friendsAccent)
                                }
                                Text("Tu primera reseña (\(existing.createdAt.formatted(date: .abbreviated, time: .omitted))) se conservará en el histórico.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Colors.friendsAccent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.small)
                                    .stroke(Theme.Colors.friendsAccent.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Theme.Colors.textTertiary)
                                Text("Publicada hace menos de 3 meses. Tu reseña se actualizará directamente.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .background(Theme.Colors.border)
                    
                    // Rating picker
                    VStack(spacing: 8) {
                        Text(existingReview != nil ? "MODIFICAR TU PUNTUACIÓN" : "TU PUNTUACIÓN")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        MinimalistRatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                    
                    // Review text
                    VStack(alignment: .leading, spacing: 6) {
                        Text(existingReview != nil ? "EDITAR OPINIÓN" : "OPINIÓN PARA TUS AMIGOS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextEditor(text: $comment)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(12)
                            .frame(height: 120)
                            .background(Theme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle(existingReview != nil ? "Editar Reseña" : "Calificar Película")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            isSubmitting = true
                            let success = await onSubmit(rating, comment)
                            isSubmitting = false
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .tint(Theme.Colors.textPrimary)
                        } else {
                            Text(existingReview != nil ? "Actualizar" : "Guardar")
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                    }
                    .disabled(rating == 0 || isSubmitting)
                }
            }
        }
    }
}
