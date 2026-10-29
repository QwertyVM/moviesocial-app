import SwiftUI

/// Hoja interactiva y minimalista para editar el perfil del usuario cinéfilo
/// Incluye personalización de avatar, biografía inteligente, director y género favorito,
/// y gestión avanzada de ubicación jerárquica (País › Región › Ciudad) conectada a API geográfica.
public struct EditProfileSheetView: View {
    public let user: User
    public let onSave: (User) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Estado del Formulario
    @State private var displayName: String
    @State private var username: String
    @State private var bio: String
    @State private var favoriteDirector: String
    @State private var favoriteGenre: String
    @State private var selectedAvatarEmoji: String
    @State private var city: String
    @State private var area: String
    @State private var country: String
    @State private var countryCode: String
    @State private var flagEmoji: String
    @State private var isDeviceLocation: Bool
    @State private var isDetectingLocation: Bool = false
    @State private var selectedCountryCode: String = "ES"
    
    // MARK: - Estado de API Geográfica y Jerarquía (País › Región › Ciudad)
    @State private var geoSearchQuery: String = ""
    @State private var geoSearchResults: [GeographicPlace] = []
    @State private var isSearchingGeoApi: Bool = false
    @State private var selectedHierarchicalRegion: String = ""
    @State private var geoSearchTask: Task<Void, Never>? = nil
    
    private let geoService: GeographicApiService = .shared
    private var availableHierarchicalCountries: [HierarchicalCountry] {
        geoService.getCountries()
    }
    private var availableHierarchicalRegions: [HierarchicalRegion] {
        geoService.getRegions(forCountryCode: countryCode.isEmpty ? "ES" : countryCode)
    }
    private var availableHierarchicalCities: [String] {
        let targetRegion = selectedHierarchicalRegion.isEmpty ? (area.isEmpty ? (availableHierarchicalRegions.first?.name ?? "") : area) : selectedHierarchicalRegion
        return geoService.getCities(forRegion: targetRegion, inCountryCode: countryCode.isEmpty ? "ES" : countryCode)
    }
    
    // MARK: - Estado de UI y Asistentes Inteligentes
    @State private var selectedTab: ProfileEditTab = .profile
    @State private var showAvatarPicker: Bool = false
    @State private var showValidationError: Bool = false
    @State private var validationErrorMessage: String = ""
    @State private var areaSearchText: String = ""
    
    private let countryGroups: [CountryAreaGroup] = ShowtimesServiceImpl().getAvailableCountryGroups()
    
    public enum ProfileEditTab: String, CaseIterable, Identifiable {
        case profile = "Identidad"
        case cinema = "Cinefilia"
        case location = "Ubicación"
        
        public var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .profile: return "person.crop.circle"
            case .cinema: return "film"
            case .location: return "mappin.and.ellipse"
            }
        }
    }
    
    // MARK: - Constantes y Datos Inteligentes
    private struct AvatarOption: Identifiable {
        let id: String
        let emoji: String
        let label: String
    }
    
    private let avatarOptions: [AvatarOption] = [
        AvatarOption(id: "director", emoji: "🎬", label: "Cineasta"),
        AvatarOption(id: "popcorn", emoji: "🍿", label: "Espectador"),
        AvatarOption(id: "camera", emoji: "🎥", label: "Cámara"),
        AvatarOption(id: "rocket", emoji: "🚀", label: "Sci-Fi"),
        AvatarOption(id: "detective", emoji: "🕵️‍♂️", label: "Noir"),
        AvatarOption(id: "star", emoji: "🌟", label: "Estrella"),
        AvatarOption(id: "classic", emoji: "🎞️", label: "Clásico"),
        AvatarOption(id: "retro", emoji: "👾", label: "Retro"),
        AvatarOption(id: "alien", emoji: "🛸", label: "Cosmos"),
        AvatarOption(id: "western", emoji: "🤠", label: "Western"),
        AvatarOption(id: "art", emoji: "🎨", label: "Autor"),
        AvatarOption(id: "masks", emoji: "🎭", label: "Drama")
    ]
    
    private struct SmartGenre: Identifiable {
        let name: String
        let icon: String
        var id: String { name }
    }
    
    private let genres: [SmartGenre] = [
        SmartGenre(name: "Ciencia Ficción", icon: "🚀"),
        SmartGenre(name: "Drama", icon: "🎭"),
        SmartGenre(name: "Thriller / Suspense", icon: "⚡"),
        SmartGenre(name: "Acción / Aventura", icon: "💥"),
        SmartGenre(name: "Terror / Psicológico", icon: "👁️"),
        SmartGenre(name: "Cine Clásico", icon: "🎞️"),
        SmartGenre(name: "Comedia", icon: "😂"),
        SmartGenre(name: "Animación", icon: "🎨"),
        SmartGenre(name: "Crimen / Neo-noir", icon: "🕵️‍♂️"),
        SmartGenre(name: "Romance", icon: "🍷"),
        SmartGenre(name: "Documental", icon: "📹"),
        SmartGenre(name: "Fantasía", icon: "🔮")
    ]
    
    private let popularDirectors: [String] = [
        "Christopher Nolan",
        "Denis Villeneuve",
        "Martin Scorsese",
        "Quentin Tarantino",
        "Stanley Kubrick",
        "Greta Gerwig",
        "David Fincher",
        "Hayao Miyazaki",
        "Guillermo del Toro",
        "Pedro Almodóvar"
    ]
    
    private let smartBioPrompts: [String] = [
        "Cinéfilo apasionado. En busca de las mejores historias.",
        "Analizando planos secuencia y coleccionando clásicos en 4K.",
        "Festivales independientes, neo-noir y guiones inolvidables.",
        "Crítico casual debatiendo finales abiertos con café.",
        "Amante de la ciencia ficción filosófica y la música de cine."
    ]
    
    // MARK: - Inicializador
    public init(user: User, onSave: @escaping (User) -> Void) {
        self.user = user
        self.onSave = onSave
        self._displayName = State(initialValue: user.displayName)
        self._username = State(initialValue: user.username)
        self._bio = State(initialValue: user.bio)
        self._favoriteDirector = State(initialValue: user.favoriteDirector)
        self._favoriteGenre = State(initialValue: user.favoriteGenre.isEmpty ? "Ciencia Ficción" : user.favoriteGenre)
        self._selectedAvatarEmoji = State(initialValue: user.avatarEmoji)
        self._city = State(initialValue: user.location?.city ?? "Madrid")
        self._area = State(initialValue: user.location?.area ?? "Comunidad de Madrid")
        self._country = State(initialValue: user.location?.country ?? "España")
        self._countryCode = State(initialValue: user.location?.countryCode ?? "ES")
        self._flagEmoji = State(initialValue: user.location?.flagEmoji ?? "🇪🇸")
        self._isDeviceLocation = State(initialValue: user.location?.isDeviceLocation ?? false)
        self._selectedCountryCode = State(initialValue: user.location?.countryCode ?? "ES")
        self._selectedHierarchicalRegion = State(initialValue: user.location?.area ?? "Comunidad de Madrid")
    }
    
    // MARK: - Estado Computado
    private var hasChanges: Bool {
        displayName != user.displayName ||
        username != user.username ||
        bio != user.bio ||
        favoriteDirector != user.favoriteDirector ||
        favoriteGenre != user.favoriteGenre ||
        selectedAvatarEmoji != user.avatarEmoji ||
        city != (user.location?.city ?? "") ||
        area != (user.location?.area ?? "") ||
        country != (user.location?.country ?? "") ||
        countryCode != (user.location?.countryCode ?? "") ||
        flagEmoji != (user.location?.flagEmoji ?? "") ||
        isDeviceLocation != (user.location?.isDeviceLocation ?? false)
    }
    
    private var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Previsualización interactiva minimalista
                    livePreviewHeader
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.top, 12)
                        .padding(.bottom, 14)
                    
                    // Selector de Pestañas Minimalista
                    customSegmentedTabs
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.bottom, 12)
                    
                    Divider()
                        .overlay(Theme.Colors.border.opacity(0.6))
                    
                    // Contenido de la pestaña activa
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .profile:
                                profileIdentitySection
                            case .cinema:
                                cinemaPreferencesSection
                            case .location:
                                smartLocationSection
                            }
                            
                            if showValidationError {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text(validationErrorMessage)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Theme.Spacing.m)
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, 18)
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDITAR PERFIL")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                    } label: {
                        HStack(spacing: 4) {
                            if hasChanges {
                                Circle()
                                    .fill(Theme.Colors.friendsAccent)
                                    .frame(width: 6, height: 6)
                            }
                            Text("Guardar")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(isFormValid ? Theme.Colors.friendsAccent : Theme.Colors.textTertiary)
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    // MARK: - Previsualización en Vivo Minimalista
    private var livePreviewHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Avatar interactivo
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showAvatarPicker.toggle()
                    }
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.surfaceElevated)
                                .frame(width: 64, height: 64)
                            
                            Text(selectedAvatarEmoji)
                                .font(.system(size: 34))
                        }
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.friendsAccent.opacity(0.8), lineWidth: 1.5)
                        )
                        .shadow(color: Theme.Colors.friendsAccent.opacity(0.2), radius: 6)
                        
                        Circle()
                            .fill(Theme.Colors.surface)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: showAvatarPicker ? "chevron.up" : "sparkles")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.Colors.friendsAccent)
                            )
                            .overlay(Circle().stroke(Theme.Colors.border, lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)
                
                // Datos del usuario en vivo
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Tu Nombre" : displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        if user.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.imdb)
                        }
                    }
                    
                    Text(cleanUsernameFormatted)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.friendsAccent)
                    
                    HStack(spacing: 6) {
                        if !city.isEmpty {
                            HStack(spacing: 3) {
                                if isDeviceLocation {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.green)
                                }
                                Text(flagEmoji)
                                    .font(.system(size: 10))
                                Text(city)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                if !area.isEmpty && area.lowercased() != city.lowercased() {
                                    Text("› \(area)")
                                        .font(.system(size: 9))
                                        .foregroundColor(Theme.Colors.textTertiary)
                                }
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.surfaceElevated)
                            .clipShape(Capsule())
                        }
                        
                        if !favoriteGenre.isEmpty {
                            Text(favoriteGenre)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.Colors.imdb)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.imdb.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
            }
            
            // Selector rápido de Avatares Cinefilos (Expandible)
            if showAvatarPicker {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ELIGE TU IDENTIDAD CINÉFILA")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .tracking(1)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(avatarOptions) { option in
                                Button {
                                    withAnimation(.spring(response: 0.25)) {
                                        selectedAvatarEmoji = option.emoji
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(option.emoji)
                                            .font(.system(size: 24))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                selectedAvatarEmoji == option.emoji ?
                                                Theme.Colors.friendsAccent.opacity(0.2) : Theme.Colors.surfaceElevated
                                            )
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedAvatarEmoji == option.emoji ? Theme.Colors.friendsAccent : Theme.Colors.border, lineWidth: 1.5)
                                            )
                                        
                                        Text(option.label)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(selectedAvatarEmoji == option.emoji ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(10)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .padding(Theme.Spacing.m)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Barra de Pestañas
    private var customSegmentedTabs: some View {
        HStack(spacing: 6) {
            ForEach(ProfileEditTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundColor(isSelected ? Theme.Colors.friendsAccent : Theme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Theme.Colors.surfaceElevated : Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isSelected ? Theme.Colors.border : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
    }
    
    // MARK: - Pestaña 1: Identidad
    private var profileIdentitySection: some View {
        VStack(spacing: 16) {
            // Nombre en pantalla
            minimalistField(
                icon: "person.fill",
                title: "NOMBRE PÚBLICO",
                placeholder: "Tu nombre o alias cinéfilo"
            ) {
                TextField("Nombre en pantalla", text: $displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .onChange(of: displayName) { _, _ in
                        showValidationError = false
                    }
            }
            
            // Nombre de usuario / handle
            minimalistField(
                icon: "at",
                title: "USUARIO ÚNICO",
                placeholder: "@tu_usuario",
                trailingAction: {
                    Button("Sugerir") {
                        withAnimation {
                            suggestIntelligentUsername()
                        }
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.Colors.friendsAccent)
                }
            ) {
                #if os(iOS)
                TextField("@usuario", text: $username)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                #else
                TextField("@usuario", text: $username)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .autocorrectionDisabled()
                #endif
            }
            
            // Biografía con sugerencias inteligentes
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.friendsAccent)
                        Text("BIOGRAFÍA CINÉFILA")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("\(bio.count)/180")
                        .font(.system(size: 10))
                        .foregroundColor(bio.count > 180 ? .red : Theme.Colors.textTertiary)
                }
                
                TextField("Escribe una breve biografía sobre tu visión del cine...", text: $bio, axis: .vertical)
                    .lineLimit(3...4)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(12)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                
                // Prompts inteligentes
                VStack(alignment: .leading, spacing: 6) {
                    Text("SUGERENCIAS INSPIRADORAS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(smartBioPrompts, id: \.self) { prompt in
                                Button {
                                    withAnimation(.spring(response: 0.2)) {
                                        bio = prompt
                                    }
                                } label: {
                                    Text(prompt)
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .lineLimit(1)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.Colors.surfaceElevated)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Theme.Colors.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
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
    }
    
    // MARK: - Pestaña 2: Cinefilia
    private var cinemaPreferencesSection: some View {
        VStack(spacing: 16) {
            // Director favorito con chips rápidos
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.friendsAccent)
                    Text("DIRECTOR PREFERIDO")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                TextField("Ej. Denis Villeneuve", text: $favoriteDirector)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(12)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                
                // Chips de directores populares
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(popularDirectors, id: \.self) { director in
                            Button {
                                withAnimation(.spring(response: 0.2)) {
                                    favoriteDirector = director
                                }
                            } label: {
                                Text(director)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(favoriteDirector == director ? Theme.Colors.friendsAccent : Theme.Colors.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(favoriteDirector == director ? Theme.Colors.friendsAccent.opacity(0.15) : Theme.Colors.surfaceElevated)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(favoriteDirector == director ? Theme.Colors.friendsAccent : Theme.Colors.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(14)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            
            // Género cinematográfico predilecto
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.friendsAccent)
                    Text("GÉNERO DE PREFERENCIA")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                FlowLayout(spacing: 8) {
                    ForEach(genres) { genre in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                favoriteGenre = genre.name
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(genre.icon)
                                    .font(.system(size: 12))
                                Text(genre.name)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(favoriteGenre == genre.name ? .white : Theme.Colors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(favoriteGenre == genre.name ? Theme.Colors.imdb.opacity(0.85) : Theme.Colors.surfaceElevated)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(favoriteGenre == genre.name ? Theme.Colors.imdb : Theme.Colors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
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
    }
    
    // MARK: - Pestaña 3: Ubicación Inteligente (Dispositivo o Jerarquía País › Región › Ciudad)
    private var smartLocationSection: some View {
        VStack(spacing: 16) {
            // Opción 1: Detección inteligente por Dispositivo (GPS/Región)
            deviceLocationCard
            
            // Opción 2: Búsqueda Predictiva en API Geográfica en Vivo
            geoApiPredictiveSearchCard
            
            // Opción 3: Cascada Jerárquica en 3 Niveles (País › Región/Estado › Ciudad)
            hierarchicalCascadeSelectorCard
            
            // Opción 4: Circuitos y Salas de Cine Locales
            countryAndAreaSelectionCard
            
            // Detalle Geográfico Exacto Editable y Miga de Pan
            geographicDetailFields
        }
    }
    
    private var deviceLocationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.green)
                Text("DETECCIÓN POR DISPOSITIVO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.green)
                
                Spacer()
                
                if isDeviceLocation {
                    Text("ACTIVO VÍA GPS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            Button {
                Task {
                    isDetectingLocation = true
                    let detected = await DeviceLocationService.shared.detectDeviceLocation()
                    city = detected.city
                    area = detected.area ?? ""
                    country = detected.country
                    countryCode = detected.countryCode
                    flagEmoji = detected.flagEmoji
                    selectedCountryCode = detected.countryCode
                    selectedHierarchicalRegion = detected.area ?? ""
                    isDeviceLocation = true
                    isDetectingLocation = false
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        if isDetectingLocation {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.green)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Detectar ubicación del dispositivo")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text(isDeviceLocation ?
                             "Sincronizado vía GPS: \(city), \(country)" :
                             "Detecta automáticamente tu país y ciudad vía GPS o región")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(12)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .stroke(isDeviceLocation ? Color.green.opacity(0.4) : Theme.Colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isDetectingLocation)
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Búsqueda Predictiva en API Geográfica
    private var geoApiPredictiveSearchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.friendsAccent)
                Text("BÚSQUEDA EN VIVO VÍA API GEOGRÁFICA")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                if isSearchingGeoApi {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                TextField("Escribe una ciudad o provincia (ej: Guadalajara, Kioto, Lyon)...", text: $geoSearchQuery)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .onChange(of: geoSearchQuery) { _, newValue in
                        performGeoApiSearch(query: newValue)
                    }
                
                if !geoSearchQuery.isEmpty {
                    Button {
                        geoSearchQuery = ""
                        geoSearchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Theme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border, lineWidth: 1))
            
            if !geoSearchResults.isEmpty {
                VStack(spacing: 6) {
                    ForEach(geoSearchResults) { place in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                city = place.city
                                area = place.region
                                country = place.country
                                countryCode = place.countryCode
                                flagEmoji = place.flagEmoji
                                selectedCountryCode = place.countryCode
                                selectedHierarchicalRegion = place.region
                                isDeviceLocation = false
                                geoSearchQuery = ""
                                geoSearchResults = []
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text(place.flagEmoji)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.city)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    Text("\(place.country) › \(place.region)")
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.Colors.textTertiary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.friendsAccent)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Colors.border, lineWidth: 1))
    }
    
    // MARK: - Cascada Jerárquica en 3 Pasos (País › Región/Estado › Ciudad)
    private var hierarchicalCascadeSelectorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "square.3.layers.3d.top.filled")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.friendsAccent)
                Text("EXPLORADOR JERÁRQUICO (PAÍS › REGIÓN › CIUDAD)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            // 1. Selector de País
            VStack(alignment: .leading, spacing: 4) {
                Text("1. PAÍS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Menu {
                    ForEach(availableHierarchicalCountries) { c in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                country = c.name
                                countryCode = c.countryCode
                                flagEmoji = c.flagEmoji
                                selectedCountryCode = c.countryCode
                                isDeviceLocation = false
                                if let firstReg = c.regions.first {
                                    area = firstReg.name
                                    selectedHierarchicalRegion = firstReg.name
                                    if let firstCity = firstReg.cities.first {
                                        city = firstCity
                                    }
                                }
                            }
                        } label: {
                            Text("\(c.flagEmoji) \(c.name)")
                        }
                    }
                } label: {
                    HStack {
                        Text(flagEmoji.isEmpty ? "🌐" : flagEmoji)
                            .font(.system(size: 16))
                        Text(country.isEmpty ? "Seleccionar País" : country)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .padding(10)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border, lineWidth: 1))
                }
            }
            
            // 2. Selector de Región / Estado / Provincia
            VStack(alignment: .leading, spacing: 4) {
                Text("2. REGIÓN / ESTADO / PROVINCIA")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                let regions = availableHierarchicalRegions
                if regions.isEmpty {
                    Text("Selecciona un país para listar sus regiones")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .padding(8)
                } else {
                    Menu {
                        ForEach(regions) { reg in
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    area = reg.name
                                    selectedHierarchicalRegion = reg.name
                                    isDeviceLocation = false
                                    if let firstCity = reg.cities.first {
                                        city = firstCity
                                    }
                                }
                            } label: {
                                Text(reg.name)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "map")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.friendsAccent)
                            Text(area.isEmpty ? "Seleccionar Región o Estado" : area)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                        .padding(10)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border, lineWidth: 1))
                    }
                }
            }
            
            // 3. Selector de Ciudad / Localidad
            VStack(alignment: .leading, spacing: 4) {
                Text("3. CIUDAD / LOCALIDAD")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                let cities = availableHierarchicalCities
                if cities.isEmpty {
                    Text("Introduce una región para explorar ciudades")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .padding(8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(cities, id: \.self) { c in
                                let isSelected = city.lowercased() == c.lowercased()
                                Button {
                                    withAnimation(.spring(response: 0.25)) {
                                        city = c
                                        isDeviceLocation = false
                                    }
                                } label: {
                                    Text(c)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                                        .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Theme.Colors.friendsAccent : Theme.Colors.surfaceElevated)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Colors.border, lineWidth: 1))
    }
    
    private var countryAndAreaSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "film.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.friendsAccent)
                Text("SALAS Y CIRCUITOS DE EXHIBICIÓN EN CARTELERA")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            // Selector horizontal de países
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(countryGroups) { group in
                        let isSelected = selectedCountryCode == group.countryCode
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedCountryCode = group.countryCode
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(group.flagEmoji)
                                Text(group.country)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Theme.Colors.friendsAccent : Theme.Colors.surfaceElevated)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Lista de áreas para el país seleccionado
            if let group = countryGroups.first(where: { $0.countryCode == selectedCountryCode }) {
                VStack(spacing: 6) {
                    ForEach(group.areas) { areaLoc in
                        let isCurrentArea = !isDeviceLocation &&
                            city.lowercased() == areaLoc.city.lowercased() &&
                            countryCode == areaLoc.countryCode
                        
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                city = areaLoc.city
                                area = areaLoc.area
                                country = areaLoc.country
                                countryCode = areaLoc.countryCode
                                flagEmoji = areaLoc.flagEmoji
                                selectedHierarchicalRegion = areaLoc.area
                                isDeviceLocation = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(areaLoc.city)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                        Text("(\(areaLoc.area))")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.Colors.textTertiary)
                                    }
                                    
                                    if !areaLoc.prominentTheaters.isEmpty {
                                        Text(areaLoc.prominentTheaters.joined(separator: " • "))
                                            .font(.system(size: 10))
                                            .foregroundColor(Theme.Colors.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                if isCurrentArea {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.friendsAccent)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isCurrentArea ? Theme.Colors.friendsAccent.opacity(0.12) : Theme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCurrentArea ? Theme.Colors.friendsAccent.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
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
    
    // MARK: - Detalle Geográfico Exacto Editable y Miga de Pan Jerárquica
    private var geographicDetailFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.friendsAccent)
                Text("DETALLES GEOGRÁFICOS EXACTOS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            // Miga de pan jerárquica activa: País › Región › Ciudad
            HStack(spacing: 6) {
                Text(flagEmoji.isEmpty ? "🌐" : flagEmoji)
                    .font(.system(size: 15))
                
                Text(country.isEmpty ? "País" : country)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Text(area.isEmpty ? "Región / Estado" : area)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Text(city.isEmpty ? "Ciudad" : city)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.friendsAccent)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1))
            
            // Ciudad y Área editables
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ciudad")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    TextField("Ciudad", text: $city)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(10)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Área / Región")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    TextField("Área o Provincia", text: $area)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(10)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                }
            }
            
            // País y Bandera
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("País")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    TextField("País", text: $country)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(10)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: country) { _, newValue in
                            autoInferFlagFromCountry(newValue)
                        }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bandera")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    ZStack {
                        Theme.Colors.surfaceElevated
                        
                        Text(flagEmoji.isEmpty ? "🌐" : flagEmoji)
                            .font(.system(size: 20))
                    }
                    .frame(width: 50, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                }
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
    
    // MARK: - Componente de Campo Minimalista Reutilizable
    private func minimalistField<Content: View, Trailing: View>(
        icon: String,
        title: String,
        placeholder: String,
        @ViewBuilder trailingAction: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.friendsAccent)
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                trailingAction()
            }
            
            content()
                .padding(12)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private func minimalistField<Content: View>(
        icon: String,
        title: String,
        placeholder: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        minimalistField(
            icon: icon,
            title: title,
            placeholder: placeholder,
            trailingAction: { EmptyView() },
            content: content
        )
    }
    
    // MARK: - Lógica Inteligente
    private var cleanUsernameFormatted: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return user.username
        }
        return trimmed.starts(with: "@") ? trimmed : "@\(trimmed)"
    }
    
    private func performGeoApiSearch(query: String) {
        geoSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            geoSearchResults = []
            isSearchingGeoApi = false
            return
        }
        
        isSearchingGeoApi = true
        geoSearchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if Task.isCancelled { return }
            let results = await geoService.searchPlaces(query: trimmed)
            if Task.isCancelled { return }
            await MainActor.run {
                self.geoSearchResults = results
                self.isSearchingGeoApi = false
            }
        }
    }
    
    private func suggestIntelligentUsername() {
        let base = displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter || $0.isNumber }
        
        if base.isEmpty {
            username = "@cinefilo_\(Int.random(in: 100...999))"
        } else {
            username = "@\(base)_cine"
        }
    }
    
    private func autoInferFlagFromCountry(_ inputCountry: String) {
        let normalized = inputCountry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return }
        
        let mapping: [String: (flag: String, code: String)] = [
            "españa": ("🇪🇸", "ES"), "spain": ("🇪🇸", "ES"), "es": ("🇪🇸", "ES"),
            "méxico": ("🇲🇽", "MX"), "mexico": ("🇲🇽", "MX"), "mx": ("🇲🇽", "MX"),
            "argentina": ("🇦🇷", "AR"), "ar": ("🇦🇷", "AR"),
            "colombia": ("🇨🇴", "CO"), "co": ("🇨🇴", "CO"),
            "chile": ("🇨🇱", "CL"), "cl": ("🇨🇱", "CL"),
            "perú": ("🇵🇪", "PE"), "peru": ("🇵🇪", "PE"), "pe": ("🇵🇪", "PE"),
            "estados unidos": ("🇺🇸", "US"), "usa": ("🇺🇸", "US"), "us": ("🇺🇸", "US"), "eeuu": ("🇺🇸", "US"),
            "francia": ("🇫🇷", "FR"), "france": ("🇫🇷", "FR"), "fr": ("🇫🇷", "FR"),
            "reino unido": ("🇬🇧", "GB"), "uk": ("🇬🇧", "GB"), "gb": ("🇬🇧", "GB"), "inglaterra": ("🇬🇧", "GB"),
            "italia": ("🇮🇹", "IT"), "italy": ("🇮🇹", "IT"), "it": ("🇮🇹", "IT"),
            "alemania": ("🇩🇪", "DE"), "germany": ("🇩🇪", "DE"), "de": ("🇩🇪", "DE"),
            "japón": ("🇯🇵", "JP"), "japan": ("🇯🇵", "JP"), "jp": ("🇯🇵", "JP"),
            "canadá": ("🇨🇦", "CA"), "canada": ("🇨🇦", "CA"), "ca": ("🇨🇦", "CA"),
            "corea del sur": ("🇰🇷", "KR"), "corea": ("🇰🇷", "KR"), "korea": ("🇰🇷", "KR"), "kr": ("🇰🇷", "KR"),
            "brasil": ("🇧🇷", "BR"), "brazil": ("🇧🇷", "BR"), "br": ("🇧🇷", "BR"),
            "uruguay": ("🇺🇾", "UY"), "uy": ("🇺🇾", "UY")
        ]
        
        if let match = mapping[normalized] {
            flagEmoji = match.flag
            countryCode = match.code
        }
    }
    
    private func saveChanges() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationErrorMessage = "El nombre no puede estar vacío."
            showValidationError = true
            return
        }
        
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = trimmedUser.isEmpty ? user.username : (trimmedUser.starts(with: "@") ? trimmedUser : "@\(trimmedUser)")
        
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedArea = area.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFlag = flagEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newLocation = UserLocation(
            city: trimmedCity.isEmpty ? (user.location?.city ?? "Madrid") : trimmedCity,
            country: trimmedCountry.isEmpty ? (user.location?.country ?? "España") : trimmedCountry,
            countryCode: countryCode.isEmpty ? (user.location?.countryCode ?? "ES") : countryCode,
            flagEmoji: trimmedFlag.isEmpty ? (user.location?.flagEmoji ?? "🇪🇸") : trimmedFlag,
            isLocal: user.location?.isLocal ?? true,
            area: trimmedArea.isEmpty ? nil : trimmedArea,
            isDeviceLocation: isDeviceLocation
        )
        
        let updatedUser = User(
            id: user.id,
            email: user.email,
            displayName: trimmedName,
            username: cleanUsername,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteDirector: favoriteDirector.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteGenre: favoriteGenre,
            avatarEmoji: selectedAvatarEmoji,
            avatarURL: user.avatarURL,
            authProvider: user.authProvider,
            createdAt: user.createdAt,
            isPremium: user.isPremium,
            location: newLocation
        )
        
        onSave(updatedUser)
        dismiss()
    }
}

// MARK: - FlowLayout Minimalista para Tags Flexibles
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        height = y + rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
