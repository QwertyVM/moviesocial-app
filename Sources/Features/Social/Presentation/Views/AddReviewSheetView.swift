import SwiftUI

/// Modal minimalista para registrar calificación y opinión
public struct AddReviewSheetView: View {
    public let movie: Movie
    public let onSubmit: (Double, String) async -> Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var rating: Double = 4.0
    @State private var comment: String = ""
    @State private var isSubmitting: Bool = false
    
    public init(movie: Movie, onSubmit: @escaping (Double, String) async -> Bool) {
        self.movie = movie
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
                    
                    Divider()
                        .background(Theme.Colors.border)
                    
                    // Rating picker
                    VStack(spacing: 8) {
                        Text("TU PUNTUACIÓN")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        MinimalistRatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                    
                    // Review text
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OPINIÓN PARA TUS AMIGOS")
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
            .navigationTitle("Calificar Película")
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
                            Text("Guardar")
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

