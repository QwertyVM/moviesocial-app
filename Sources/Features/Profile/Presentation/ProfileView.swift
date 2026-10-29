import SwiftUI

public struct ProfileView: View {
    public let user: User
    @Bindable public var viewModel: ProfileViewModel
    public let onSelectMovie: ((String) -> Void)?
    public let onUpdateUser: ((User) -> Void)?
    public let onSignOut: () -> Void
    
    @State private var isEditingProfile: Bool = false
    @State private var toastMessage: String?
    @State private var showConfirmResetAlert: Bool = false
    
    public init(
        user: User,
        viewModel: ProfileViewModel,
        onSelectMovie: ((String) -> Void)? = nil,
        onUpdateUser: ((User) -> Void)? = nil,
        onSignOut: @escaping () -> Void
    ) {
        self.user = user
        self.viewModel = viewModel
        self.onSelectMovie = onSelectMovie
        self.onUpdateUser = onUpdateUser
        self.onSignOut = onSignOut
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Toast informativo
                        if let toast = toastMessage {
                            toastBanner(toast)
                        }
                        
                        // Cabecera Minimalista
                        minimalistHeader
                        
                        // Barra de Métricas Unificada
                        minimalistMetricsBar
                        
                        // Gustos Cinéfilos Minimalistas
                        minimalistCinemaTags
                        
                        // Estado de Membresía
                        minimalistMembershipRow
                        
                        // Mis Calificaciones y Reseñas
                        myReviewsSection
                        
                        // Estado y Mantenimiento de Base de Datos SQLite
                        databaseSection
                        
                        // Botón Sutil de Cerrar Sesión
                        signOutButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
                .refreshable {
                    await viewModel.loadProfileData(user: user)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PERFIL")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                // Único botón de edición en MI PERFIL
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
            .alert("¿Reiniciar Base de Datos?", isPresented: $showConfirmResetAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Reiniciar Todo", role: .destructive) {
                    Task {
                        await viewModel.resetDatabase(user: user)
                        showToast("Base de datos reiniciada con éxito")
                    }
                }
            } message: {
                Text("Esta acción eliminará todas las tablas SQLite locales y reiniciará los datos a su estado limpio inicial.")
            }
            .task {
                await viewModel.loadProfileData(user: user)
            }
        }
    }
    
    // MARK: - Minimalist Header
    
    private var minimalistHeader: some View {
        VStack(spacing: 12) {
            // Avatar Puro
            ZStack {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 86, height: 86)
                
                if !user.avatarEmoji.isEmpty {
                    Text(user.avatarEmoji)
                        .font(.system(size: 44))
                } else {
                    Text(String(user.displayName.prefix(1)))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .overlay(
                Circle()
                    .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: Theme.Colors.friendsAccent.opacity(0.12), radius: 10)
            
            // Textos de Identidad
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(user.username)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.friendsAccent)
                
                // Ubicación y Proveedor Inline Minimalista
                HStack(spacing: 8) {
                    if let location = user.location {
                        Text(location.formattedText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    if user.location != nil {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: user.authProvider == .apple ? "applelogo" : "globe")
                            .font(.system(size: 10))
                        Text(user.authProvider.rawValue.capitalized)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(.top, 2)
                
                // Biografía Cinéfila
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                }
            }
        }
    }
    
    // MARK: - Minimalist Metrics Bar
    
    private var minimalistMetricsBar: some View {
        HStack(spacing: 0) {
            metricItem(title: "CRÍTICAS", value: "\(viewModel.userReviewsCount)")
            
            Divider()
                .frame(height: 26)
                .background(Theme.Colors.border.opacity(0.4))
            
            metricItem(title: "PROMEDIO", value: String(format: "%.1f", viewModel.averageGivenRating))
            
            Divider()
                .frame(height: 26)
                .background(Theme.Colors.border.opacity(0.4))
            
            metricItem(title: "AMIGOS", value: "\(viewModel.friendsCount)")
        }
        .padding(.vertical, 14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
        )
    }
    
    private func metricItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Minimalist Cinema Tags
    
    private var minimalistCinemaTags: some View {
        HStack(spacing: 10) {
            // Director Favorito
            HStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.friendsAccent)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("DIRECTOR")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text(user.favoriteDirector.isEmpty ? "Sin definir" : user.favoriteDirector)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
            )
            
            // Género Predilecto
            HStack(spacing: 8) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.imdb)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("GÉNERO")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text(user.favoriteGenre.isEmpty ? "Sin definir" : user.favoriteGenre)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Minimalist Membership Row
    
    private var minimalistMembershipRow: some View {
        HStack(spacing: 12) {
            Image(systemName: user.isPremium ? "crown.fill" : "person.crop.circle.badge.checkmark")
                .font(.system(size: 16))
                .foregroundColor(user.isPremium ? Theme.Colors.imdb : Theme.Colors.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    (user.isPremium ? Theme.Colors.imdb : Theme.Colors.textSecondary)
                        .opacity(0.12)
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.isPremium ? "Cinéfilo PRO" : "Pase Social")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if user.isPremium {
                        Text("ACTIVO")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Theme.Colors.imdb)
                            .clipShape(Capsule())
                    }
                }
                
                Text(user.isPremium ? "Críticas globales ilimitadas y análisis de autor." : "Opiniones de tu red cercana de cinéfilos.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(user.isPremium ? Theme.Colors.imdb.opacity(0.3) : Theme.Colors.border.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - My Reviews Section
    
    private var myReviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "star.bubble.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.imdb)
                    
                    Text("MIS CALIFICACIONES (\(viewModel.userReviews.count))")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                if !viewModel.userReviews.isEmpty {
                    Text("Promedio: \(String(format: "%.1f", viewModel.averageGivenRating)) ★")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.imdb)
                }
            }
            .padding(.horizontal, 2)
            
            if viewModel.userReviews.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text("Aún no has calificado películas")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Tus notas y opiniones aparecerán aquí cuando valores películas en el catálogo de Cine.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.userReviews) { review in
                        userReviewCard(review)
                    }
                }
            }
        }
    }
    
    private func userReviewCard(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Cabecera con película y calificación
            Button {
                onSelectMovie?(review.movieId)
            } label: {
                HStack(spacing: 12) {
                    if let poster = review.moviePosterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Theme.Colors.surfaceElevated)
                        }
                        .frame(width: 42, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(review.movieTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        if let year = review.movieReleaseYear {
                            Text("\(year)")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("★")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.imdb)
                        Text(review.formattedRating)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                    
                    if onSelectMovie != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Comentario
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
                    .padding(.top, 2)
            }
            
            // Pie con fecha y likes / comentarios
            HStack {
                Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Spacer()
                
                if review.likesCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.8))
                        Text("\(review.likesCount)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                
                if !review.comments.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.friendsAccent)
                        Text("\(review.comments.count)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
        )
    }
    
    // MARK: - Database & REST Services Management
    
    private var databaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "network")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.friendsAccent)
                Text("SERVICIOS REST Y BASE DE DATOS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("API REST Activa")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 2)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Servicios HTTP Conectados a BD")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("database.sqlite • GET, POST, PUT, DELETE")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    Spacer()
                }
                
                // Métodos HTTP soportados
                HStack(spacing: 6) {
                    Text("GET")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Text("POST")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                    Text("PUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                    Text("DELETE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                // Métrica de tablas en BD
                if !viewModel.databaseStats.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(["reviews", "friends", "movie_groups", "direct_conversations"], id: \.self) { table in
                            if let count = viewModel.databaseStats[table] {
                                let label = table == "reviews" ? "reseñas" : (table == "friends" ? "amigos" : (table == "movie_groups" ? "grupos" : "chats"))
                                Text("\(count) \(label)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Theme.Colors.surfaceElevated)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                
                Divider()
                    .background(Theme.Colors.border.opacity(0.5))
                    .padding(.vertical, 2)
                
                Button {
                    showConfirmResetAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 12))
                        Text("Reiniciar Base de Datos y Datos Iniciales")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Sign Out
    
    private var signOutButton: some View {
        Button(role: .destructive, action: onSignOut) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13))
                Text("Cerrar Sesión")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.red.opacity(0.85))
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.red.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
    
    // MARK: - Helpers
    
    private func toastBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.friendsAccent)
            Text(text)
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
    
    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                self.toastMessage = nil
            }
        }
    }
}
