import SwiftUI

public struct ProfileView: View {
    public let user: User
    @Bindable public var viewModel: ProfileViewModel
    public let onSignOut: () -> Void
    
    public init(user: User, viewModel: ProfileViewModel, onSignOut: @escaping () -> Void) {
        self.user = user
        self.viewModel = viewModel
        self.onSignOut = onSignOut
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // User Header
                        userHeader
                        
                        // Minimalist Stats Row
                        statsRow
                        
                        // Friends List Section
                        friendsSection
                        
                        // Sign Out Button
                        Button(role: .destructive, action: onSignOut) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Cerrar Sesión")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Theme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        }
                        .padding(.top, Theme.Spacing.m)
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
                    Text("MI PERFIL")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .task {
                await viewModel.loadProfileData(user: user)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var userHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Theme.Colors.surfaceElevated)
                .frame(width: 72, height: 72)
                .overlay(
                    Text(String(user.displayName.prefix(1)))
                        .font(.title.bold())
                        .foregroundColor(Theme.Colors.textPrimary)
                )
                .overlay(
                    Circle()
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title3.bold())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                // Auth Provider badge
                HStack(spacing: 4) {
                    Image(systemName: user.authProvider == .apple ? "applelogo" : "globe")
                        .font(.system(size: 10))
                    Text("Conectado con \(user.authProvider.rawValue)")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
                .padding(.top, 2)
            }
        }
        .padding(.top, Theme.Spacing.s)
    }
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "CALIFICADAS", value: "\(viewModel.userReviewsCount)")
            statCard(title: "NOTA MEDIA", value: String(format: "%.1f", viewModel.averageGivenRating))
            statCard(title: "AMIGOS", value: "\(viewModel.friendsCount)")
        }
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(Theme.Colors.textPrimary)
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AMIGOS CONECTADOS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.Colors.textSecondary)
            
            if viewModel.friends.isEmpty {
                Text("No tienes amigos agregados todavía.")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textTertiary)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.friends) { friend in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Theme.Colors.surfaceElevated)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Text(String(friend.displayName.prefix(1)))
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.Colors.textPrimary)
                                )
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(friend.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Text(friend.username)
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text("\(friend.mutualMoviesCount) en común")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.Colors.friendsAccent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Theme.Colors.surfaceElevated)
                                .clipShape(Capsule())
                        }
                        .padding(10)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

