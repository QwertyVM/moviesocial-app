import SwiftUI

public struct ProfileView: View {
    public let user: User
    @Bindable public var viewModel: ProfileViewModel
    public let onUpdateUser: ((User) -> Void)?
    public let onSignOut: () -> Void
    
    @State private var selectedFriend: Friend? = nil
    @State private var isEditingProfile: Bool = false
    @State private var toastMessage: String? = nil
    
    public init(
        user: User,
        viewModel: ProfileViewModel,
        onUpdateUser: ((User) -> Void)? = nil,
        onSignOut: @escaping () -> Void
    ) {
        self.user = user
        self.viewModel = viewModel
        self.onUpdateUser = onUpdateUser
        self.onSignOut = onSignOut
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Toast informativo
                        if let toast = toastMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.friendsAccent)
                                Text(toast)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.surfaceElevated)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.Colors.friendsAccent.opacity(0.6), lineWidth: 1))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // User Header
                        userHeader
                        
                        // Cinema Preferences Card
                        cinemaPreferencesCard
                        
                        // Membership Status Card
                        membershipCard
                        
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
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isEditingProfile = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Editar")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.friendsAccent)
                    }
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileSheetView(user: user) { updatedUser in
                    onUpdateUser?(updatedUser)
                    showToast("Perfil actualizado correctamente")
                }
            }
            .task {
                await viewModel.loadProfileData(user: user)
            }
            .sheet(item: $selectedFriend) { friend in
                NavigationStack {
                    ZStack {
                        Theme.Colors.background
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            Circle()
                                .fill(Theme.Colors.surfaceElevated)
                                .frame(width: 76, height: 76)
                                .overlay(
                                    Text(String(friend.displayName.prefix(1)))
                                        .font(.title.bold())
                                        .foregroundColor(Theme.Colors.textPrimary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.border, lineWidth: 1.5)
                                )
                            
                            VStack(spacing: 4) {
                                Text(friend.displayName)
                                    .font(.title3.bold())
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Text(friend.username)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.textTertiary)
                                
                                HStack(spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "film")
                                            .font(.system(size: 10))
                                        Text("\(friend.mutualMoviesCount) películas en común")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(Theme.Colors.friendsAccent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Theme.Colors.friendsAccent.opacity(0.12))
                                    .clipShape(Capsule())
                                    
                                    if friend.isMutual {
                                        Text("Amigos mutuos")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Theme.Colors.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.Colors.surfaceElevated)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 30)
                    }
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") {
                                selectedFriend = nil
                            }
                            .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var userHeader: some View {
        VStack(spacing: 12) {
            // Avatar con Icono o Inicial
            ZStack {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 80, height: 80)
                
                if !user.avatarEmoji.isEmpty {
                    Text(user.avatarEmoji)
                        .font(.system(size: 40))
                } else {
                    Text(String(user.displayName.prefix(1)))
                        .font(.title.bold())
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .overlay(
                Circle()
                    .stroke(Theme.Colors.border, lineWidth: 1.5)
            )
            .shadow(color: Theme.Colors.friendsAccent.opacity(0.15), radius: 6)
            
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title3.bold())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(user.username)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.Colors.friendsAccent)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                // Badges de Proveedor de Autenticación y Ubicación
                HStack(spacing: 6) {
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
                    
                    if let location = user.location {
                        Text(location.formattedText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
                
                // Biografía cinéfila
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                }
                
                // Botón rápido para editar perfil
                Button {
                    isEditingProfile = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                        Text("Editar Perfil")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.friendsAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Theme.Colors.friendsAccent.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.friendsAccent.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding(.top, Theme.Spacing.s)
    }
    
    private var cinemaPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GUSTOS CINÉFILOS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                Button {
                    isEditingProfile = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.friendsAccent)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                // Director Favorito
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.friendsAccent)
                        Text("DIRECTOR(A)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    
                    Text(user.favoriteDirector.isEmpty ? "No especificado" : user.favoriteDirector)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Género Predilecto
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "film.stack.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.imdb)
                        Text("GÉNERO")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    
                    Text(user.favoriteGenre.isEmpty ? "No especificado" : user.favoriteGenre)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                self.toastMessage = nil
            }
        }
    }
    
    private var membershipCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(user.isPremium ? Theme.Colors.imdb.opacity(0.15) : Theme.Colors.surfaceElevated)
                    .frame(width: 40, height: 40)
                
                Image(systemName: user.isPremium ? "crown.fill" : "lock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(user.isPremium ? Theme.Colors.imdb : Theme.Colors.textTertiary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.isPremium ? "CINÉFILO PRO" : "PASE SOCIAL")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(user.isPremium ? Theme.Colors.imdb : Theme.Colors.textPrimary)
                    
                    if user.isPremium {
                        Text("ACTIVO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Theme.Colors.imdb)
                            .clipShape(Capsule())
                    }
                }
                
                Text(user.isPremium ? "Acceso ilimitado a críticas locales y globales fuera de tu lista de amigos." : "Desbloquea opiniones globales y locales de cinéfilos de todo el mundo.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(user.isPremium ? Theme.Colors.imdb.opacity(0.4) : Theme.Colors.border, lineWidth: 1)
        )
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
            HStack {
                Text("AMIGOS CONECTADOS (\(viewModel.friendsCount))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
            }
            
            if viewModel.friends.isEmpty {
                Text("No tienes amigos agregados todavía.")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textTertiary)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.friends) { friend in
                        Button {
                            selectedFriend = friend
                        } label: {
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
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            .padding(10)
                            .background(Theme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

