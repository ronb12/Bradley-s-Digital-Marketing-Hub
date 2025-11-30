import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    enum AuthState {
        case loading
        case onboarding
        case notificationsOnboarding
        case authenticated
    }

    @Published var authState: AuthState = .loading
    @Published var userProfile: UserProfile?
    @Published var brands: [Brand] = []
    @Published var campaignPlans: [CampaignPlan] = []
    @Published var calendarItems: [ContentCalendarItem] = []
    @Published var templates: [TemplateItem] = []
    @Published var affiliateTools: [AffiliateTool] = []
    @Published var selectedBrand: Brand?
    @Published var showPaywall = false
    @Published var errorMessage: String?

    let cloudKitService = CloudKitService()
    let authService = AuthService()
    let subscriptionManager = SubscriptionManager()

    private var didBootstrap = false

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        await subscriptionManager.loadProducts()
        await subscriptionManager.refreshEntitlements()

        if let cachedId = authService.cachedUserId(),
           let profile = try? await cloudKitService.fetchUserProfile(userId: cachedId) {
            userProfile = profile
            subscriptionManager.overrideTier(profile.plan)
            authState = .authenticated
            await refreshPortal()
        } else {
            authState = .onboarding
        }
    }

    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        authService.prepareRequest(request)
    }

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    let payload = try authService.payload(from: authorization)
                    if let existing = try await cloudKitService.fetchUserProfile(userId: payload.userId) {
                        await MainActor.run {
                            self.userProfile = existing
                            self.subscriptionManager.overrideTier(existing.plan)
                            self.authState = .notificationsOnboarding
                        }
                    } else {
                        let profile = UserProfile(
                            userId: payload.userId,
                            name: payload.fullName?.formatted(),
                            email: payload.email,
                            businessName: nil,
                            businessType: nil,
                            plan: .free,
                            createdAt: Date()
                        )
                        let saved = try await cloudKitService.upsertUserProfile(profile)
                        await MainActor.run {
                            self.userProfile = saved
                            self.subscriptionManager.overrideTier(.free)
                            self.authState = .notificationsOnboarding
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func completeNotificationsOnboarding(enableReminders: Bool) async {
        // Store onboarding preference locally for now.
        UserDefaults.standard.set(enableReminders, forKey: "BradleyDigitalMarketingHub.notificationsEnabled")
        authState = .authenticated
        await refreshPortal()
    }

    func refreshPortal() async {
        guard let profile = userProfile else { return }
        async let brandsTask = fetchBrands(for: profile)
        async let campaignsTask = fetchCampaigns(for: profile)
        async let calendarTask = fetchCalendar(for: profile)
        async let templatesTask = loadTemplates()
        async let toolsTask = loadAffiliateTools()

        if let brands = try? await brandsTask {
            self.brands = brands
            if selectedBrand == nil { selectedBrand = brands.first }
        }
        if let plans = try? await campaignsTask {
            campaignPlans = plans
        }
        if let items = try? await calendarTask {
            calendarItems = items
        }
        if let templates = try? await templatesTask {
            self.templates = templates
        }
        if let tools = try? await toolsTask {
            affiliateTools = tools
        }
    }

    private func fetchBrands(for profile: UserProfile) async throws -> [Brand] {
        try await cloudKitService.fetchBrands(userId: profile.userId)
    }

    private func fetchCampaigns(for profile: UserProfile) async throws -> [CampaignPlan] {
        try await cloudKitService.fetchCampaignPlans(userId: profile.userId, brandId: selectedBrand?.id)
    }

    private func fetchCalendar(for profile: UserProfile) async throws -> [ContentCalendarItem] {
        try await cloudKitService.fetchCalendarItems(userId: profile.userId, brandId: selectedBrand?.id)
    }

    private func loadTemplates() async throws -> [TemplateItem] {
        try await cloudKitService.fetchTemplates()
    }

    private func loadAffiliateTools() async throws -> [AffiliateTool] {
        try await cloudKitService.fetchAffiliateTools()
    }

    func signOut() {
        authService.signOut()
        userProfile = nil
        brands = []
        campaignPlans = []
        calendarItems = []
        templates = []
        affiliateTools = []
        selectedBrand = nil
        subscriptionManager.overrideTier(.free)
        authState = .onboarding
    }

    func saveCampaignPlan(_ plan: CampaignPlan) async {
        do {
            let saved = try await cloudKitService.saveCampaignPlan(plan)
            campaignPlans.insert(saved, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCalendarItem(_ item: ContentCalendarItem) async {
        do {
            let saved = try await cloudKitService.saveCalendarItem(item)
            calendarItems.append(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBrand(_ brand: Brand) async {
        do {
            let saved = try await cloudKitService.saveBrand(brand)
            brands.append(saved)
            selectedBrand = saved
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBooking(_ booking: Booking) async {
        do {
            _ = try await cloudKitService.saveBooking(booking)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logAffiliateClick(tool: AffiliateTool) async {
        guard let profile = userProfile else { return }
        let click = AffiliateClick(userId: profile.userId, toolId: tool.id)
        do {
            try await cloudKitService.logAffiliateClick(click)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func seedDemoData() async throws -> DemoSeedResult {
        guard let profile = userProfile else {
            throw CloudKitError.operationFailed("Missing user profile for demo data seeding.")
        }
        let seeder = DemoDataSeeder(cloudKitService: cloudKitService)
        let result = try await seeder.seed(for: profile.userId)
        await refreshPortal()
        return result
    }

    func updatePlan(to tier: SubscriptionTier) async {
        guard var profile = userProfile else { return }
        profile.plan = tier
        do {
            let saved = try await cloudKitService.upsertUserProfile(profile)
            userProfile = saved
            subscriptionManager.overrideTier(tier)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var currentTier: SubscriptionTier {
        subscriptionManager.currentTier
    }

    func canAddCampaignPlan() -> Bool {
        guard let limit = currentTier.maxCampaignPlans else { return true }
        return campaignPlans.count < limit
    }

    func canAddCalendarItem() -> Bool {
        guard let limit = currentTier.maxCalendarItems else { return true }
        return calendarItems.count < limit
    }

    func canAddBrand() -> Bool {
        brands.count < currentTier.maxBrands
    }

    func allowedTemplates() -> [TemplateItem] {
        templates.availableTemplates(for: currentTier)
    }
}
