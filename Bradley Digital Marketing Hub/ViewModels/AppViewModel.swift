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

    @Published var authState: AuthState = .onboarding
    @Published var userProfile: UserProfile?
    @Published var brands: [Brand] = []
    @Published var campaignPlans: [CampaignPlan] = []
    @Published var calendarItems: [ContentCalendarItem] = []
    @Published var templates: [TemplateItem] = []
    @Published var affiliateTools: [AffiliateTool] = []
    @Published var selectedBrand: Brand?
    @Published var showPaywall = false
    @Published var errorMessage: String?
    @Published var isDemoMode = false

    let cloudKitService = CloudKitService()
    let authService = AuthService()
    let subscriptionManager = SubscriptionManager()
    let themeManager = ThemeManager.shared
    lazy var socialMediaService = SocialMediaService(cloudKitService: cloudKitService)

    private var didBootstrap = false

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        
        // Immediately transition to onboarding to show content
        // Don't block on anything - show welcome screen right away
        await MainActor.run {
            authState = .onboarding
        }
        
        // Start loading products and entitlements in background (don't block)
        Task { @MainActor in
            await self.subscriptionManager.loadProducts()
        }
        Task { @MainActor in
            await self.subscriptionManager.refreshEntitlements()
        }

        // Quick check for cached user in background - don't block
        if let cachedId = authService.cachedUserId() {
            Task {
                do {
                    let profile = try await cloudKitService.fetchUserProfile(userId: cachedId)
                    if let profile = profile {
                        await MainActor.run {
                            userProfile = profile
                            subscriptionManager.overrideTier(profile.plan)
                            authState = .authenticated
                        }
                        await refreshPortal()
                    }
                } catch {
                    // CloudKit might fail - that's OK, stay on onboarding
                    print("CloudKit fetch failed (this is OK on first launch): \(error.localizedDescription)")
                }
            }
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
        // Store onboarding preference locally
        UserDefaults.standard.set(enableReminders, forKey: "BradleyDigitalMarketingHub.notificationsEnabled")
        
        // Request notification permissions if user enabled reminders
        if enableReminders {
            do {
                let granted = try await NotificationService.shared.requestAuthorization()
                if granted {
                    NotificationService.shared.registerNotificationCategories()
                    print("Notification permissions granted")
                } else {
                    print("Notification permissions denied")
                }
            } catch {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
        
        authState = .authenticated
        await refreshPortal()
    }

    func enterDemoMode() {
        guard !isDemoMode else { return }
        isDemoMode = true
        didBootstrap = true
        let demoUserId = "demo-user"
        let demoBrand = DemoData.brands(userId: demoUserId)
        userProfile = UserProfile(
            userId: demoUserId,
            name: "Demo User",
            businessName: "Social Labs Co.",
            businessType: "Marketing Services",
            plan: .pro,
            createdAt: Date()
        )
        brands = demoBrand
        selectedBrand = brands.first
        campaignPlans = DemoData.campaignPlans(userId: demoUserId, brandId: selectedBrand?.id)
        calendarItems = DemoData.calendarItems(userId: demoUserId, brandId: selectedBrand?.id)
        templates = DemoData.templates
        affiliateTools = DemoData.affiliateTools
        subscriptionManager.overrideTier(.pro)
        authState = .authenticated
        errorMessage = "Demo mode is read-only. Sign in with Apple for full functionality."
    }

    func refreshPortal() async {
        guard let profile = userProfile else { return }
        guard !isDemoMode else { return }
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
        isDemoMode = false
        didBootstrap = false
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
        guard !isDemoMode else {
            errorMessage = "Demo mode is read-only. Sign in to save campaign plans."
            return
        }
        do {
            let saved = try await cloudKitService.saveCampaignPlan(plan)
            campaignPlans.insert(saved, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCalendarItem(_ item: ContentCalendarItem) async {
        guard !isDemoMode else {
            errorMessage = "Demo mode is read-only. Sign in to schedule items."
            return
        }
        do {
            let saved = try await cloudKitService.saveCalendarItem(item)
            calendarItems.append(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBrand(_ brand: Brand) async {
        guard !isDemoMode else {
            errorMessage = "Demo mode is read-only. Sign in to add brands."
            return
        }
        do {
            let saved = try await cloudKitService.saveBrand(brand)
            brands.append(saved)
            selectedBrand = saved
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBooking(_ booking: Booking) async {
        guard !isDemoMode else {
            errorMessage = "Demo mode is read-only. Sign in to book services."
            return
        }
        do {
            _ = try await cloudKitService.saveBooking(booking)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logAffiliateClick(tool: AffiliateTool) async {
        guard !isDemoMode else { return }
        guard let profile = userProfile else { return }
        let click = AffiliateClick(userId: profile.userId, toolId: tool.id)
        do {
            try await cloudKitService.logAffiliateClick(click)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func seedDemoData() async throws -> DemoSeedResult {
        guard !isDemoMode else {
            throw CloudKitError.operationFailed("Seed is disabled in demo mode. Sign in with Apple to publish CloudKit data.")
        }
        guard let profile = userProfile else {
            throw CloudKitError.operationFailed("Missing user profile for demo data seeding.")
        }
        let seeder = DemoDataSeeder(cloudKitService: cloudKitService)
        let result = try await seeder.seed(for: profile.userId)
        await refreshPortal()
        return result
    }

    func updateAvatar(with data: Data) async {
        guard !isDemoMode else {
            errorMessage = "Demo mode is read-only. Sign in to update your avatar."
            return
        }
        guard let profile = userProfile else { return }
        do {
            let updated = try await cloudKitService.updateUserAvatar(data: data, userId: profile.userId)
            userProfile = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAvatar() async {
        guard !isDemoMode else {
            errorMessage = "Demo mode is read-only. Sign in to update your avatar."
            return
        }
        guard let profile = userProfile else { return }
        do {
            let updated = try await cloudKitService.removeUserAvatar(userId: profile.userId)
            userProfile = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePlan(to tier: SubscriptionTier) async {
        guard !isDemoMode else {
            subscriptionManager.overrideTier(tier)
            return
        }
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
