import Foundation

@MainActor
final class AffiliateToolsViewModel: ObservableObject {
    func badgeText(for tool: AffiliateTool, tier: SubscriptionTier) -> String? {
        if tool.isProRecommended {
            return tier == .free ? "Pro Recommended" : "Recommended"
        }
        return nil
    }
}
