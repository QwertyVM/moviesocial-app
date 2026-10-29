import SwiftUI

/// Vista modal para editar la información, biografía y preferencias cinematográficas del usuario
public struct EditProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    public let user: User
    public let onSave: (User) -> Void
    
    @State private var displayName: String
    @State private var username: String
    @State private var bio: String
    @State private var favoriteDirector: String
    @State private var favoriteGenre: String
    @State private var selectedAvatarEmoji: String
    @State private var city: String
    @State private var country: String
    @State private var flagEmoji: String
    @State private var showValidationError: Bool = false
    @State private var validationErrorMessage: String = ""
    
    private let availableEmojis = ["🎬", "🍿", "🚀", "🎭", "🎥", "🌟", "👾", "🕵️‍♂️", "🛸", "🤠", "🖤", "🎞️"]
    private let availableGenres = [
        "Ciencia Ficción",
        "Drama",
        "Thriller / Suspense",
        "Acción / Aventura",
        "Terror / Psicológico",
        "Cine Clásico",
        "Comedia",
        "Animación",
        "Crimen / Neo-noir",
        "Documental"
    ]
    
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
        self._country = State(initialValue: user.location?.country ?? "España")
        self._flagEmoji = State(initialValue: user.location?.flagEmoji ?? "🇪🇸")
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Selector de Avatar Emoji
                        avatarSelectionSection
                        
                        // Campos de Información Personal
                        personalInfoSection
                        
                        // Preferencias Cinéfilas
                        cinemaPreferencesSection
                        
                        // Ubicación
                        locationSection
                        
                        // Mensaje de Error si hay validación
                        if showValidationError {
                            Text(validationErrorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }
                        
                        // Botón Guardar
                        saveButton
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, 16)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDITAR PERFIL")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
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
                    Button("Guardar") {
                        saveChanges()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.friendsAccent)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var avatarSelectionSection: some View {
        VStack(spacing: 12) {
            // Preview actual
            ZStack {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 80, height: 80)
                
                Text(selectedAvatarEmoji)
                    .font(.system(size: 42))
            }
            .overlay(
                Circle()
                    .stroke(Theme.Colors.friendsAccent.opacity(0.6), lineWidth: 2)
            )
            .shadow(color: Theme.Colors.friendsAccent.opacity(0.2), radius: 8)
            
            Text("SELECCIONA TU ICONO CINÉFILO")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(Theme.Colors.textTertiary)
            
            // Carrusel de emojis
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableEmojis, id: \.self) { emoji in
                        Button {
                            selectedAvatarEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 26))
                                .frame(width: 44, height: 44)
                                .background(selectedAvatarEmoji == emoji ? Theme.Colors.friendsAccent.opacity(0.25) : Theme.Colors.surface)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedAvatarEmoji == emoji ? Theme.Colors.friendsAccent : Theme.Colors.border, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INFORMACIÓN PERSONAL")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Nombre
            VStack(alignment: .leading, spacing: 6) {
                Text("Nombre Completo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                TextField("Tu nombre", text: $displayName)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(12)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
            }
            
            // Nombre de usuario
            VStack(alignment: .leading, spacing: 6) {
                Text("Nombre de Usuario")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                TextField("@usuario", text: $username)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .padding(12)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
            }
            
            // Biografía
            VStack(alignment: .leading, spacing: 6) {
                Text("Biografía Cinéfila")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                #if os(iOS)
                TextField("Escribe una breve biografía sobre tus gustos...", text: $bio, axis: .vertical)
                    .lineLimit(3...5)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(12)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                #else
                TextField("Escribe una breve biografía sobre tus gustos...", text: $bio)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(12)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                #endif
            }
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var cinemaPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PREFERENCIAS DE CINE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Director favorito
            VStack(alignment: .leading, spacing: 6) {
                Text("Director(a) Favorito(a)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                TextField("Ej. Christopher Nolan, Denis Villeneuve, Kubrick...", text: $favoriteDirector)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(12)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
            }
            
            // Género predilecto
            VStack(alignment: .leading, spacing: 6) {
                Text("Género Predilecto")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Picker("Género", selection: $favoriteGenre) {
                    ForEach(availableGenres, id: \.self) { genre in
                        Text(genre).tag(genre)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("UBICACIÓN")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.Colors.textSecondary)
            
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ciudad")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    TextField("Ciudad", text: $city)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(12)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("País")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    TextField("País", text: $country)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(12)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bandera")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    TextField("🇪🇸", text: $flagEmoji)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(width: 44)
                        .padding(12)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                Text("Guardar Cambios del Perfil")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Theme.Colors.friendsAccent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.plain)
    }
    
    private func saveChanges() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            validationErrorMessage = "El nombre no puede estar vacío."
            showValidationError = true
            return
        }
        
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = trimmedUser.isEmpty ? user.username : (trimmedUser.starts(with: "@") ? trimmedUser : "@\(trimmedUser)")
        
        let newLocation = UserLocation(
            city: city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (user.location?.city ?? "Madrid") : city.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (user.location?.country ?? "España") : country.trimmingCharacters(in: .whitespacesAndNewlines),
            countryCode: user.location?.countryCode ?? "ES",
            flagEmoji: flagEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (user.location?.flagEmoji ?? "🇪🇸") : flagEmoji.trimmingCharacters(in: .whitespacesAndNewlines),
            isLocal: user.location?.isLocal ?? true
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
