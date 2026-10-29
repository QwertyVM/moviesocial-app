import SwiftUI

/// Hoja minimalista e inteligente para seleccionar la ubicación de la cartelera
/// Soporta detección automática por dispositivo (GPS/Región), búsqueda en vivo mediante API geográfica
/// y exploración jerárquica exacta por País › Región/Estado › Ciudad.
public struct LocationSelectorSheetView: View {
    @Bindable var viewModel: MovieCatalogViewModel
    var onLocationSelected: ((UserLocation) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedCountryFilter: String? = nil
    @State private var selectedViewMode: LocationViewMode = .theaters
    
    // MARK: - Estado de Búsqueda y Jerarquía en API Geográfica
    @State private var geoSearchResults: [GeographicPlace] = []
    @State private var isSearchingGeoApi: Bool = false
    @State private var geoSearchTask: Task<Void, Never>? = nil
    
    @State private var selectedCascadeCountryCode: String = "ES"
    @State private var selectedCascadeRegion: String = "Comunidad de Madrid"
    
    private let geoService = GeographicApiService.shared
    
    public enum LocationViewMode: String, CaseIterable, Identifiable {
        case theaters = "Circuitos de Cine"
        case hierarchy = "Jerarquía (País › Región › Ciudad)"
        
        public var id: String { rawValue }
    }
    
    public init(
        viewModel: MovieCatalogViewModel,
        onLocationSelected: ((UserLocation) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onLocationSelected = onLocationSelected
    }
    
    private var availableCascadeCountries: [HierarchicalCountry] {
        geoService.getCountries()
    }
    
    private var availableCascadeRegions: [HierarchicalRegion] {
        geoService.getRegions(forCountryCode: selectedCascadeCountryCode)
    }
    
    private var availableCascadeCities: [String] {
        geoService.getCities(forRegion: selectedCascadeRegion, inCountryCode: selectedCascadeCountryCode)
    }
    
    private var filteredGroups: [CountryAreaGroup] {
        var groups = viewModel.countryGroups
        
        if let filter = selectedCountryFilter {
            groups = groups.filter { $0.countryCode == filter }
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return groups }
        
        return groups.compactMap { group in
            let matchesCountry = group.country.lowercased().contains(query)
            let matchingAreas = group.areas.filter { area in
                area.city.lowercased().contains(query) ||
                area.area.lowercased().contains(query) ||
                area.prominentTheaters.contains { $0.lowercased().contains(query) }
            }
            
            if matchesCountry {
                return group
            } else if !matchingAreas.isEmpty {
                return CountryAreaGroup(
                    country: group.country,
                    countryCode: group.countryCode,
                    flagEmoji: group.flagEmoji,
                    areas: matchingAreas
                )
            }
            return nil
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    currentActiveLocationCard
                    
                    deviceLocationCard
                    
                    searchField
                    
                    if !geoSearchResults.isEmpty {
                        liveGeoApiResultsCard
                    }
                    
                    viewModePicker
                    
                    if selectedViewMode == .theaters {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SALAS Y CIRCUITOS DE EXHIBICIÓN")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.Colors.textTertiary)
                                .tracking(1.5)
                            
                            countryFilterChips
                            countryAreasList
                        }
                    } else {
                        hierarchicalExplorerCard
                    }
                }
                .padding(Theme.Spacing.m)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Ubicación y Cartelera")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Tarjeta de Ubicación Activa con Jerarquía
    private var currentActiveLocationCard: some View {
        HStack(spacing: 10) {
            Text(viewModel.selectedCity.flagEmoji)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("UBICACIÓN SELECCIONADA")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .tracking(1)
                
                Text(viewModel.selectedCity.hierarchicalFormattedText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if viewModel.selectedCity.isDeviceLocation {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text("GPS")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.border, lineWidth: 1))
    }
    
    // MARK: - Tarjeta Inteligente de Ubicación del Dispositivo
    private var deviceLocationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("DETECCIÓN INTELIGENTE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .tracking(1.2)
                
                Spacer()
                
                if viewModel.selectedCity.isDeviceLocation {
                    Text("ACTIVO")
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
                    await viewModel.useDeviceLocation()
                    onLocationSelected?(viewModel.selectedCity)
                    dismiss()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        if viewModel.isDetectingLocation {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.green)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Usar ubicación del dispositivo")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text(viewModel.selectedCity.isDeviceLocation ?
                             "Sincronizado vía GPS: \(viewModel.selectedCity.city), \(viewModel.selectedCity.country)" :
                             "Detecta automáticamente tu país y ciudad mediante GPS o región")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(14)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.selectedCity.isDeviceLocation ? Color.green.opacity(0.4) : Theme.Colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isDetectingLocation)
        }
    }
    
    // MARK: - Barra de Búsqueda
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.textTertiary)
                .font(.system(size: 13))
            
            TextField("Buscar país, región, ciudad o sala (ej: Lyon, Kioto)...", text: $searchText)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textPrimary)
                .onChange(of: searchText) { _, newValue in
                    performGeoSearch(query: newValue)
                }
            
            if isSearchingGeoApi {
                ProgressView()
                    .scaleEffect(0.7)
            }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    geoSearchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.textTertiary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Resultados en Vivo de API Geográfica
    private var liveGeoApiResultsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.friendsAccent)
                Text("RESULTADOS API GEOGRÁFICA (PAÍS › REGIÓN › CIUDAD)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            VStack(spacing: 6) {
                ForEach(geoSearchResults) { place in
                    Button {
                        let userLoc = place.toUserLocation()
                        Task {
                            await viewModel.selectCity(userLoc)
                            onLocationSelected?(userLoc)
                            dismiss()
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
                            
                            Text("Seleccionar")
                                .font(.system(size: 11, weight: .semibold))
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
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.friendsAccent.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Selector de Modo de Vista
    private var viewModePicker: some View {
        HStack(spacing: 6) {
            ForEach(LocationViewMode.allCases) { mode in
                let isSelected = selectedViewMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedViewMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isSelected ? Theme.Colors.friendsAccent : Theme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
    }
    
    // MARK: - Explorador Jerárquico (País › Región › Ciudad)
    private var hierarchicalExplorerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SELECCIÓN JERÁRQUICA ESTRUCTURADA")
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.Colors.textTertiary)
            
            // 1. País
            VStack(alignment: .leading, spacing: 4) {
                Text("1. PAÍS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Menu {
                    ForEach(availableCascadeCountries) { c in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedCascadeCountryCode = c.countryCode
                                if let firstReg = c.regions.first {
                                    selectedCascadeRegion = firstReg.name
                                }
                            }
                        } label: {
                            Text("\(c.flagEmoji) \(c.name)")
                        }
                    }
                } label: {
                    let country = availableCascadeCountries.first(where: { $0.countryCode == selectedCascadeCountryCode })
                    HStack {
                        Text(country?.flagEmoji ?? "🌐")
                            .font(.system(size: 16))
                        Text(country?.name ?? "Seleccionar País")
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
            
            // 2. Región / Estado
            VStack(alignment: .leading, spacing: 4) {
                Text("2. REGIÓN / ESTADO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Menu {
                    ForEach(availableCascadeRegions) { reg in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedCascadeRegion = reg.name
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
                        Text(selectedCascadeRegion)
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
            
            // 3. Ciudad / Localidad
            VStack(alignment: .leading, spacing: 4) {
                Text("3. CIUDAD / LOCALIDAD (TOCA PARA ACTIVAR)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.textTertiary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableCascadeCities, id: \.self) { c in
                            let isCurrent = viewModel.selectedCity.city.lowercased() == c.lowercased()
                            Button {
                                let country = availableCascadeCountries.first(where: { $0.countryCode == selectedCascadeCountryCode })
                                let userLoc = UserLocation(
                                    city: c,
                                    country: country?.name ?? "España",
                                    countryCode: selectedCascadeCountryCode,
                                    flagEmoji: country?.flagEmoji ?? "🇪🇸",
                                    isLocal: true,
                                    area: selectedCascadeRegion,
                                    isDeviceLocation: false
                                )
                                Task {
                                    await viewModel.selectCity(userLoc)
                                    onLocationSelected?(userLoc)
                                    dismiss()
                                }
                            } label: {
                                Text(c)
                                    .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                                    .foregroundColor(isCurrent ? .white : Theme.Colors.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isCurrent ? Theme.Colors.recommendationAccent : Theme.Colors.surfaceElevated)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(isCurrent ? Color.clear : Theme.Colors.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.border, lineWidth: 1))
    }
    
    // MARK: - Chips de Países
    private var countryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedCountryFilter = nil
                } label: {
                    Text("Todos")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCountryFilter == nil ? Theme.Colors.friendsAccent : Theme.Colors.surface)
                        .foregroundColor(selectedCountryFilter == nil ? .white : Theme.Colors.textSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                ForEach(viewModel.countryGroups) { group in
                    let isSelected = selectedCountryFilter == group.countryCode
                    Button {
                        if isSelected {
                            selectedCountryFilter = nil
                        } else {
                            selectedCountryFilter = group.countryCode
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(group.flagEmoji)
                            Text(group.country)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Theme.Colors.friendsAccent : Theme.Colors.surface)
                        .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
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
    }
    
    // MARK: - Lista Agrupada de Países y Áreas
    private var countryAreasList: some View {
        VStack(spacing: 16) {
            ForEach(filteredGroups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(group.flagEmoji)
                            .font(.system(size: 16))
                        Text(group.country.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(group.areas.count) áreas disponibles")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 6) {
                        ForEach(group.areas) { area in
                            areaRow(area: area)
                        }
                    }
                }
                .padding(12)
                .background(Theme.Colors.surfaceElevated.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 1)
                )
            }
        }
    }
    
    private func areaRow(area: AreaLocation) -> some View {
        let isSelected = !viewModel.selectedCity.isDeviceLocation &&
            viewModel.selectedCity.city.lowercased() == area.city.lowercased() &&
            viewModel.selectedCity.countryCode == area.countryCode
        
        return Button {
            let userLoc = area.toUserLocation
            Task {
                await viewModel.selectCity(userLoc)
                onLocationSelected?(userLoc)
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(area.city)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("(\(area.area))")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    
                    if !area.prominentTheaters.isEmpty {
                        Text(area.prominentTheaters.joined(separator: " • "))
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.recommendationAccent)
                        Text("Cartelera activa")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.Colors.recommendationAccent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.recommendationAccent.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.Colors.surfaceElevated : Theme.Colors.surface.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Theme.Colors.recommendationAccent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func performGeoSearch(query: String) {
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
}
