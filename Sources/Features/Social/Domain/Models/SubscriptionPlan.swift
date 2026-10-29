import Foundation

public struct SubscriptionPlan: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let priceText: String
    public let periodText: String
    public let badge: String?
    public let isPopular: Bool
    public let trialText: String?
    
    public init(
        id: String,
        title: String,
        subtitle: String,
        priceText: String,
        periodText: String,
        badge: String? = nil,
        isPopular: Bool = false,
        trialText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.priceText = priceText
        self.periodText = periodText
        self.badge = badge
        self.isPopular = isPopular
        self.trialText = trialText
    }
    
    public static let standardPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "plan_annual_pro",
            title: "Pase Anual Pro",
            subtitle: "Facturado anualmente. Ahorra un 44% y obtén todas las funciones.",
            priceText: "US$ 19.99",
            periodText: "/ año (~US$ 1.66/mes)",
            badge: "MÁS POPULAR",
            isPopular: true,
            trialText: "7 días de prueba gratis"
        ),
        SubscriptionPlan(
            id: "plan_monthly",
            title: "Pase Mensual",
            subtitle: "Acceso total flexible mes a mes. Cancela cuando quieras.",
            priceText: "US$ 2.99",
            periodText: "/ mes",
            badge: nil,
            isPopular: false,
            trialText: "Prueba sin compromiso"
        ),
        SubscriptionPlan(
            id: "plan_single_movie",
            title: "Pase para esta Película",
            subtitle: "Desbloquea opiniones globales y locales solo para este título.",
            priceText: "US$ 0.99",
            periodText: "pago único",
            badge: "MICRO-PAGO",
            isPopular: false,
            trialText: "Sin suscripción recurrente"
        )
    ]
}
