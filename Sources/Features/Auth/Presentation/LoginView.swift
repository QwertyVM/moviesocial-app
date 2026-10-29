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
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 54, weight: .light))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("CINEPHILE")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(4)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Comparte cine con tus amigos sin ruido ni noticias.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, 40)
                    
                    // Rating badges preview
                    HStack(spacing: 8) {
                        Text("🍅 Rotten Tomatoes")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.rottenTomatoesCritics)
                        Text("•")
                            .foregroundColor(Theme.Colors.textTertiary)
                        Text("★ IMDb")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.imdb)
                        Text("•")
                            .foregroundColor(Theme.Colors.textTertiary)
                        Text("👥 Amigos")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.friendsAccent)
                    }
                    .padding(.top, 6)
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
                        HStack(spacing: 10) {
                            Image(systemName: "applelogo")
                                .font(.body.bold())
                            Text("Continuar con Apple")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Sign in with Google Button
                    Button {
                        Task {
                            await viewModel.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("G")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.white)
                            Text("Continuar con Google")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.Colors.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                    }
                    .disabled(viewModel.isLoading)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.Colors.textPrimary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }
}

