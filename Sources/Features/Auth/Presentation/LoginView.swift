import SwiftUI

/// Pantalla minimalista de autenticación con Apple y Google
public struct LoginView: View {
    @Bindable public var viewModel: AuthViewModel
    
    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                
                // Minimalist Branding
                VStack(spacing: 14) {
                    Image(systemName: "film")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("MOVIESOCIAL")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(6)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Cine con amigos, sin ruido ni algoritmos publicitarios.")
                        .font(.system(size: 13.5))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, 40)
                    
                    // Rating badges preview minimalista
                    HStack(spacing: 12) {
                        metricTag(label: "RT", color: Theme.Colors.rottenTomatoesCritics)
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.Colors.textTertiary)
                        metricTag(label: "IMDb", color: Theme.Colors.imdb)
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.Colors.textTertiary)
                        metricTag(label: "Amigos", color: Theme.Colors.friendsAccent)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // Auth Actions
                VStack(spacing: 12) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Sign in with Apple Button
                    Button {
                        Task {
                            await viewModel.signInWithApple()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Continuar con Apple")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Sign in with Google Button
                    Button {
                        Task {
                            await viewModel.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("G")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("Continuar con Google")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.Colors.border, lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(viewModel.isLoading)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.Colors.textTertiary)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }
    
    private func metricTag(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
    }
}
