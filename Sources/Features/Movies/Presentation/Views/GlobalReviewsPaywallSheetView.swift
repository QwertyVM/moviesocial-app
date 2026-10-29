import SwiftUI

public struct GlobalReviewsPaywallSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    public let movieTitle: String
    public let onSubscribeSuccess: () -> Void
    
    @State private var selectedPlanId: String = "plan_annual_pro"
    @State private var isProcessing: Bool = false
    @State private var showSuccessCheckmark: Bool = false
    
    private let plans = SubscriptionPlan.standardPlans
    
    public init(movieTitle: String, onSubscribeSuccess: @escaping () -> Void) {
        self.movieTitle = movieTitle
        self.onSubscribeSuccess = onSubscribeSuccess
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l) {
                        // Header Visual
                        heroHeaderView
                        
                        // Value Propositions
                        valuePropositionsView
                        
                        // Plan Selector
                        planSelectorView
                        
                        // CTA Button
                        ctaButtonView
                        
                        // Legal & Restore
                        footerView
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.l)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var heroHeaderView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 68, height: 68)
                    .overlay(
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.imdb, Color.orange, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
                    )
            }
            
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("PASE SOCIAL DE PAGA")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(Theme.Colors.imdb)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.Colors.imdb.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Text("Crítica Global & Local")
                    .font(.title2.bold())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("Descubre qué opinan espectadores de tu ciudad y de todo el mundo que no están en tu lista de amigos.")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.top, 4)
    }
    
    private var valuePropositionsView: some View {
        VStack(spacing: 14) {
            featureRow(
                icon: "mappin.and.ellipse",
                color: Color.green,
                title: "Opiniones Locales de Cines",
                description: "Reacciones auténticas de espectadores en tu ciudad, salas locales y festivales cercanos."
            )
            
            featureRow(
                icon: "globe.americas.fill",
                color: Color.blue,
                title: "Perspectiva Internacional",
                description: "Lee comentarios de cinéfilos en Tokio, París, Nueva York, Seúl y más en su idioma y contexto."
            )
            
            featureRow(
                icon: "person.crop.circle.badge.plus",
                color: Theme.Colors.friendsAccent,
                title: "Conoce a Nuevos Cinéfilos",
                description: "Descubre personas fuera de tu círculo con tus mismos gustos cinematográficos y agrégalas."
            )
            
            featureRow(
                icon: "hand.thumbsup.fill",
                color: Color.orange,
                title: "Votos Útiles e Interacción Total",
                description: "Vota qué reseñas fueron más útiles, participa en hilos de debate y comenta libremente."
            )
        }
        .padding(Theme.Spacing.m)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
    
    private var planSelectorView: some View {
        VStack(spacing: 10) {
            ForEach(plans) { plan in
                planCard(plan: plan)
            }
        }
    }
    
    private func planCard(plan: SubscriptionPlan) -> some View {
        let isSelected = selectedPlanId == plan.id
        
        return Button {
            selectedPlanId = plan.id
        } label: {
            HStack(spacing: 12) {
                // Radio indicator
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? Theme.Colors.imdb : Theme.Colors.textTertiary)
                    .font(.system(size: 18))
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(plan.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(isSelected ? .black : Theme.Colors.imdb)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isSelected ? Theme.Colors.imdb : Theme.Colors.imdb.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(plan.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.priceText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(plan.periodText)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            .padding(14)
            .background(isSelected ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(isSelected ? Theme.Colors.imdb : Theme.Colors.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var ctaButtonView: some View {
        Button {
            handlePurchase()
        } label: {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .tint(.black)
                } else if showSuccessCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("¡Pase Desbloqueado!")
                        .fontWeight(.bold)
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 15))
                    Text("Desbloquear con Apple Pay")
                        .fontWeight(.bold)
                }
            }
            .font(.subheadline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.imdb, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .shadow(color: Theme.Colors.imdb.opacity(0.3), radius: 8, y: 3)
        }
        .disabled(isProcessing || showSuccessCheckmark)
    }
    
    private var footerView: some View {
        VStack(spacing: 8) {
            Button("Restaurar Compras") {
                handleRestore()
            }
            .font(.caption)
            .foregroundColor(Theme.Colors.textTertiary)
            
            Text("La suscripción se renovará automáticamente a menos que se cancele al menos 24 horas antes del final del período actual en los Ajustes de tu Apple ID.")
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.textTertiary.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Handlers
    
    private func handlePurchase() {
        isProcessing = true
        
        Task {
            // Simular interacción de compra con Apple StoreKit / In-App Purchases
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                isProcessing = false
                showSuccessCheckmark = true
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                onSubscribeSuccess()
                dismiss()
            }
        }
    }
    
    private func handleRestore() {
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                onSubscribeSuccess()
                dismiss()
            }
        }
    }
}
