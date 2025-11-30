import Foundation

@MainActor
final class CampaignPlannerViewModel: ObservableObject {
    @Published var platform: MarketingPlatform = .instagram
    @Published var budget: Double = 500
    @Published var goal: String = "Awareness"
    @Published var selectedBrand: Brand?
    @Published var outline: String = ""
    @Published var statusMessage: String?
    @Published var isSaving = false

    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func generateOutline() {
        let duration = budget < 1000 ? 7 : 14
        outline = """
        Platform: \(platform.rawValue)
        Goal: \(goal)
        Hook Ideas: Share an origin story and behind-the-scenes moments.
        Content Themes: Testimonials Tuesday, Data-drop Thursday, Weekend Wins.
        CTA Suggestions: Book a call, Grab the template, Download the checklist.
        Duration: \(duration) day sprint.
        Budget Allocation: Paid ads \(Int(budget * 0.4))$, creators \(Int(budget * 0.3))$, tools \(Int(budget * 0.3))$.
        """
    }

    func savePlan(userId: String, brandId: String?, currentCount: Int, tier: SubscriptionTier) async {
        if let limit = tier.maxCampaignPlans, currentCount >= limit {
            statusMessage = "Upgrade to unlock more campaign plans."
            return
        }
        guard !outline.isEmpty else {
            statusMessage = "Generate a plan before saving."
            return
        }
        isSaving = true
        defer { isSaving = false }
        let plan = CampaignPlan(
            userId: userId,
            brandId: brandId,
            platform: platform.rawValue,
            budget: budget,
            goal: goal,
            outlineDetails: outline
        )
        do {
            _ = try await service.saveCampaignPlan(plan)
            statusMessage = "Campaign saved to CloudKit."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
