import SwiftUI

public struct MovieDetailView: View {
    @Bindable public var viewModel: MovieDetailViewModel
    public let currentUser: User?
    public var onUpgradeToPremium: (() -> Void)?
    
    @State private var expandedHistoryReviewIds: Set<String> = []
    
    public init(
        viewModel: MovieDetailViewModel,
        currentUser: User?,
        onUpgradeToPremium: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onUpgradeToPremium = onUpgradeToPremium
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // Hero Header con Póster y Datos Esenciales
                heroHeaderView
                
                // Badges Oficiales: Rotten Tomatoes, IMDb y Amigos / Global
                VStack(alignment: .leading, spacing: 6) {
                    Text("PUNTUACIONES")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    RatingBadgesView(
                        ratings: viewModel.movie.ratings,
                        friendsAverage: viewModel.friendsAverageRating,
                        friendsCount: viewModel.friendReviews.count
                    )
                }
                .padding(.horizontal, Theme.Spacing.m)
                
                // Botón Calificar o Editar Reseña Propia
                if let myReview = viewModel.userReview(userId: currentUser?.id) {
                    userReviewCard(myReview)
                        .padding(.horizontal, Theme.Spacing.m)
                } else {
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
                }
                
                // Sinopsis
                VStack(alignment: .leading, spacing: 6) {
                    Text("SINOPSIS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(viewModel.movie.overview)
                        .font(.subheadline)
                        .lineSpacing(4)
                        .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
                }
                .padding(.horizontal, Theme.Spacing.m)
                
                // Cartelera y Horarios en Cines Locales (si está disponible)
                if viewModel.movie.isInTheatersLocally || !viewModel.movie.localShowtimes.isEmpty {
                    theatersSection
                        .padding(.horizontal, Theme.Spacing.m)
                }
                
                Divider()
                    .background(Theme.Colors.border)
                    .padding(.horizontal, Theme.Spacing.m)
                
                // Sección Social y Crítica Comunitaria (Amigos, Locales e Internacionales)
                socialCommunitySection
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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .sheet(isPresented: $viewModel.isPresentingAddReview) {
            AddReviewSheetView(
                movie: viewModel.movie,
                existingReview: viewModel.userReview(userId: currentUser?.id)
            ) { rating, comment in
                guard let user = currentUser else { return false }
                return await viewModel.submitReview(rating: rating, comment: comment, currentUser: user)
            }
        }
        .sheet(isPresented: $viewModel.isPresentingPaywall) {
            GlobalReviewsPaywallSheetView(movieTitle: viewModel.movie.title) {
                viewModel.subscribeUser()
                onUpgradeToPremium?()
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
            await viewModel.loadDetails(currentUser: currentUser)
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
    
    private var theatersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color.green)
                Text("EN CARTELERA LOCAL")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
            }
            
            // Badges de Ciclo de Exhibición (Estreno / 2ª Semana) y Cine Nacional
            let status = viewModel.movie.releaseStatus()
            HStack(spacing: 8) {
                if status == .premiereWeek {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text("SEMANA DE ESTRENO")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.15))
                    .clipShape(Capsule())
                } else if status == .secondWeek {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("2ª SEMANA EN CINES")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.3, green: 0.8, blue: 1.0))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.3, green: 0.8, blue: 1.0).opacity(0.15))
                    .clipShape(Capsule())
                }
                
                if let country = viewModel.movie.countryOfOrigin, !country.isEmpty {
                    Text(nationalCinemaDescription(for: country))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Theme.Colors.border, lineWidth: 1)
                        )
                }
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.movie.localShowtimes) { showtime in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(showtime.cinemaName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text(showtime.roomFormat)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.Colors.recommendationAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.surfaceElevated)
                                .clipShape(Capsule())
                        }
                        
                        if !showtime.times.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(showtime.times, id: \.self) { time in
                                    Text(time)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.Colors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Theme.Colors.border, lineWidth: 1)
                                        )
                                }
                            }
                        }
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
        }
    }
    
    private var socialCommunitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header con selector de Filtro
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("OPINIONES Y CRÍTICAS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        if viewModel.isSubscribed {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Theme.Colors.imdb)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                if !viewModel.isSubscribed {
                    Button {
                        viewModel.isPresentingPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("Pase Global")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Theme.Colors.imdb)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.imdb.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Selector de Categoría (Todos, Amigos, Locales, Internacionales)
            filterTabsView
            
            // Sub-métricas cuando está desbloqueado
            if viewModel.isSubscribed {
                ratingsSummaryRow
            }
            
            // Contenido según el estado
            if viewModel.selectedFilter == .local && !viewModel.isSubscribed {
                paywallTeaserCard(
                    title: "Opiniones Locales de Espectadores",
                    subtitle: "Descubre qué opinan cinéfilos de tu misma ciudad y cines cercanos que no están en tu lista de amigos."
                )
            } else if viewModel.selectedFilter == .international && !viewModel.isSubscribed {
                paywallTeaserCard(
                    title: "Crítica Internacional Abierta",
                    subtitle: "Lee impresiones auténticas de Tokio, París, Nueva York y más allá de tu círculo social."
                )
            } else {
                reviewsListView
                
                // Si el usuario está viendo "Todos" o "Amigos" y aún no es pro, mostramos el teaser abajo para incentivarlo
                if !viewModel.isSubscribed {
                    paywallTeaserCard(
                        title: "Desbloquea la Crítica Local e Internacional",
                        subtitle: "Hay +140 opiniones de cinéfilos en tu ciudad y en todo el mundo esperando por ti."
                    )
                }
            }
        }
    }
    
    private var filterTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReviewFilter.allCases) { filter in
                    let isSelected = viewModel.selectedFilter == filter
                    let isLocked = !viewModel.isSubscribed && (filter == .local || filter == .international)
                    
                    Button {
                        if isLocked {
                            viewModel.isPresentingPaywall = true
                        } else {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filter.iconName)
                                .font(.system(size: 10))
                            
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                            
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(Theme.Colors.imdb)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
                        .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Theme.Colors.border : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var ratingsSummaryRow: some View {
        HStack(spacing: 12) {
            if let avg = viewModel.friendsAverageRating {
                HStack(spacing: 3) {
                    Text("👥 Amigos:")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("★ \(String(format: "%.1f", avg))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.Colors.friendsAccent)
                }
            }
            
            if let locAvg = viewModel.localAverageRating {
                HStack(spacing: 3) {
                    Text("📍 Local:")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("★ \(String(format: "%.1f", locAvg))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.green)
                }
            }
            
            if let intAvg = viewModel.internationalAverageRating {
                HStack(spacing: 3) {
                    Text("🌐 Global:")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("★ \(String(format: "%.1f", intAvg))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.blue)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Theme.Colors.surfaceElevated.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
    }
    
    private var reviewsListView: some View {
        VStack(spacing: 10) {
            if viewModel.displayedReviews.isEmpty {
                VStack(spacing: 6) {
                    Text("No hay opiniones en esta categoría aún.")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("Sé el primero en compartir tu punto de vista.")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.displayedReviews) { review in
                    reviewRow(review)
                }
            }
        }
    }
    
    private func paywallTeaserCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.imdb.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "globe.europe.africa.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.imdb)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("PASE SOCIAL DE PAGA")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Theme.Colors.imdb)
                    }
                    
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineSpacing(2)
                }
            }
            
            // Blurred Teaser Review Cards
            VStack(spacing: 6) {
                sampleBlurredReviewRow(
                    flagText: "🇪🇸 Madrid, España",
                    author: "Carlos N. • Cines Callao",
                    rating: "★ 4.5",
                    textSnippet: "El sonido en la sala te hace vibrar el pecho, la dirección de arte es insuperable..."
                )
                
                sampleBlurredReviewRow(
                    flagText: "🇯🇵 Tokio, Japón",
                    author: "Kenji S. • Grand Cinema Sunshine",
                    rating: "★ 5.0",
                    textSnippet: "池袋のIMAXレーザーGTで鑑賞。圧倒的な重低音と映像美に息を呑んだ..."
                )
            }
            .padding(8)
            .background(Theme.Colors.surfaceElevated.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            
            // Unlock Button
            Button {
                viewModel.isPresentingPaywall = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 12))
                    Text("Desbloquear Opiniones Globales y Locales")
                        .font(.system(size: 13, weight: .bold))
                    Text("• Desde US$ 0.99")
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.imdb, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.imdb.opacity(0.35), lineWidth: 1)
        )
    }
    
    private func sampleBlurredReviewRow(flagText: String, author: String, rating: String, textSnippet: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.imdb)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(flagText)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("•")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text(author)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Spacer()
                    Text(rating)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.imdb)
                }
                
                Text(textSnippet)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .blur(radius: 2.2)
                    .lineLimit(1)
            }
        }
        .padding(6)
    }
    
    private func reviewRow(_ review: Review) -> some View {
        let isAddedFriend = viewModel.addedFriendUsernames.contains(review.userName)
        let isFriendRelation = review.isFriend || isAddedFriend
        
        return VStack(alignment: .leading, spacing: 10) {
            // Header: Avatar, Name, Location badge, Friend tag, Rating
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
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(review.userName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        // Badge de Ubicación (Local o Internacional)
                        if let loc = review.location {
                            Text(loc.formattedText)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(loc.isLocal ? Color.green : Color.blue)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background((loc.isLocal ? Color.green : Color.blue).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        // Estado de Amistad
                        if isFriendRelation {
                            Text("👥 Amigo")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.Colors.friendsAccent)
                        } else {
                            Text("👤 Fuera de amigos")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Botón añadir a amigos si no es amigo aún
                if !isFriendRelation {
                    Button {
                        Task {
                            _ = await viewModel.addFriendFromReview(userName: review.userName)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 10))
                            Text("Añadir")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(Theme.Colors.friendsAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.friendsAccent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
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
            
            // Comentario / Opinión de la película
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineSpacing(3)
            }
            
            // Histórico de primera reseña si fue editada tras > 3 meses
            if review.hasHistoricalRecord {
                historicalReviewSection(for: review)
            }
            
            // Última respuesta si hay comentarios
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
            
            // Bottom actions (Like, Voto Útil, Responder)
            HStack(spacing: 16) {
                // Like
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
                
                // Voto Útil
                Button {
                    guard let user = currentUser else { return }
                    Task {
                        await viewModel.toggleHelpful(reviewId: review.id, user: user)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: review.isHelpfulByMe ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: 12))
                            .foregroundColor(review.isHelpfulByMe ? Theme.Colors.imdb : Theme.Colors.textTertiary)
                        Text(review.helpfulCount > 0 ? "Útil (\(review.helpfulCount))" : "¿Útil?")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(review.isHelpfulByMe ? Theme.Colors.imdb : Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                // Responder / Ver hilos de debate
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
    
    private func userReviewCard(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.friendsAccent)
                    Text("TU RESEÑA")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.Colors.friendsAccent)
                }
                
                Spacer()
                
                Button {
                    viewModel.isPresentingAddReview = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                        Text("Editar mi reseña")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Text("★")
                        .foregroundColor(Theme.Colors.imdb)
                    Text(review.formattedRating)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
                
                if review.isEdited {
                    Text("Editada")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineSpacing(2)
            }
            
            if review.hasHistoricalRecord {
                historicalReviewSection(for: review)
            }
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.friendsAccent.opacity(0.4), lineWidth: 1)
        )
    }
    
    private func historicalReviewSection(for review: Review) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedHistoryReviewIds.contains(review.id) {
                        expandedHistoryReviewIds.remove(review.id)
                    } else {
                        expandedHistoryReviewIds.insert(review.id)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10))
                    Text(expandedHistoryReviewIds.contains(review.id) ? "Ocultar histórico" : "Ver primera reseña (Histórico)")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: expandedHistoryReviewIds.contains(review.id) ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundColor(Theme.Colors.friendsAccent)
            }
            .buttonStyle(.plain)
            
            if expandedHistoryReviewIds.contains(review.id) {
                ForEach(review.history) { hist in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("PRIMERA RESEÑA (HISTÓRICO)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.Colors.friendsAccent)
                            Spacer()
                            HStack(spacing: 2) {
                                Text("★")
                                    .foregroundColor(Theme.Colors.imdb)
                                Text(hist.formattedRating)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                        }
                        if !hist.comment.isEmpty {
                            Text("\"\(hist.comment)\"")
                                .font(.system(size: 11))
                                .italic()
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        Text("Publicada el \(hist.createdAt.formatted(date: .abbreviated, time: .omitted)) • Archivada el \(hist.archivedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.surfaceElevated.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(.top, 2)
    }
    
    private func nationalCinemaDescription(for code: String) -> String {
        switch code.uppercased() {
        case "PE": return "🇵🇪 Cine Peruano"
        case "ES": return "🇪🇸 Cine Español"
        case "MX": return "🇲🇽 Cine Mexicano"
        case "AR": return "🇦🇷 Cine Argentino"
        case "FR": return "🇫🇷 Cine Francés"
        case "JP": return "🇯🇵 Cine Japonés"
        case "CO": return "🇨🇴 Cine Colombiano"
        case "CL": return "🇨🇱 Cine Chileno"
        case "US": return "🇺🇸 Producción USA"
        default: return "🎬 Cine Local"
        }
    }
}
