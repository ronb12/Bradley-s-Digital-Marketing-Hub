import Foundation
import AuthenticationServices
import SwiftUI
import CloudKit

@MainActor
final class AppViewModel: ObservableObject {
    enum AuthState {
        case loading
        case onboarding
        case manualShareOnboarding
        case notificationsOnboarding
        case authenticated
    }

    @Published var authState: AuthState = .onboarding
    @Published var userProfile: UserProfile?
    @Published var brands: [Brand] = []
    @Published var campaignPlans: [CampaignPlan] = []
    @Published var calendarItems: [ContentCalendarItem] = []
    @Published var scheduledPosts: [ScheduledPost] = []
    @Published var templates: [TemplateItem] = []
    @Published var affiliateTools: [AffiliateTool] = []
    @Published var selectedBrand: Brand?
    @Published var showPaywall = false
    @Published var errorMessage: String?
    @Published var isDemoMode = false
    @Published var demoModeBanner: String?
    @Published var isRefreshingPortal = false

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
                        await activateSchedulingPipeline()
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
                            self.authState = .manualShareOnboarding
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
                            self.authState = .manualShareOnboarding
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

    func completeManualShareOnboarding() {
        authState = .notificationsOnboarding
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
        await activateSchedulingPipeline()
    }

    private func activateSchedulingPipeline() async {
        guard let userId = userProfile?.userId, !isDemoMode else {
            PostScheduler.shared.stopScheduling()
            return
        }

        PostScheduler.shared.configure(service: socialMediaService)
        PostScheduler.shared.startScheduling(socialMediaService: socialMediaService, userId: userId)
        PostScheduler.shared.scheduleBackgroundTask()

        do {
            let posts = try await socialMediaService.fetchScheduledPosts(userId: userId)
            await NotificationService.shared.rescheduleAllReminders(
                userId: userId,
                posts: posts,
                service: socialMediaService
            )
            await socialMediaService.processScheduledPosts(userId: userId)
        } catch {
            print("Failed to sync scheduling pipeline: \(error.localizedDescription)")
        }
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
        demoModeBanner = "Demo mode is read-only. Sign in with Apple for a personal workspace."
        errorMessage = nil
    }

    func refreshPortal() async {
        guard let profile = userProfile else { return }
        guard !isDemoMode else { return }
        isRefreshingPortal = true
        defer { isRefreshingPortal = false }

        async let brandsTask = fetchBrands(for: profile)
        async let campaignsTask = fetchCampaigns(for: profile)
        async let calendarTask = fetchCalendar(for: profile)
        async let templatesTask = loadTemplates()
        async let toolsTask = loadAffiliateTools()
        async let postsTask = fetchScheduledPosts(for: profile)

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
        if let posts = try? await postsTask {
            scheduledPosts = posts
        }

        await activateSchedulingPipeline()
    }

    private func fetchScheduledPosts(for profile: UserProfile) async throws -> [ScheduledPost] {
        try await socialMediaService.fetchScheduledPosts(userId: profile.userId)
    }

    func scheduleContent(
        title: String,
        content: String,
        platform: MarketingPlatform,
        date: Date,
        enableReminder: Bool,
        mediaURLs: [String] = []
    ) async throws {
        guard !isDemoMode else {
            throw CloudKitError.operationFailed(HubMessages.demoReadOnly)
        }
        guard let userId = userProfile?.userId else {
            throw CloudKitError.operationFailed("Sign in to schedule content.")
        }
        if let limit = currentTier.maxCalendarItems, calendarItems.count >= limit {
            throw CloudKitError.operationFailed("Calendar limit reached for your plan.")
        }

        let item = ContentCalendarItem(
            userId: userId,
            brandId: selectedBrand?.id,
            date: date,
            platform: platform.rawValue,
            title: title,
            notes: content
        )
        let savedItem = try await cloudKitService.saveCalendarItem(item)
        calendarItems.append(savedItem)

        if enableReminder {
            let scheduledPost = ScheduledPost(
                userId: userId,
                brandId: selectedBrand?.id,
                calendarItemId: savedItem.id,
                platform: platform.rawValue,
                content: content,
                scheduledDate: date,
                status: .scheduled,
                mediaURLs: mediaURLs
            )
            let savedPost = try await socialMediaService.saveScheduledPost(scheduledPost)
            scheduledPosts.append(savedPost)
            try? await NotificationService.shared.schedulePostReminder(for: savedPost)
        }

        await activateSchedulingPipeline()
    }

    func markPostShared(forCalendarItem calendarItemId: String) async {
        guard !isDemoMode else { return }
        guard let post = scheduledPosts.first(where: { $0.calendarItemId == calendarItemId }) else { return }
        do {
            let updated = try await socialMediaService.updatePostStatus(post, status: .shared)
            if let index = scheduledPosts.firstIndex(where: { $0.id == updated.id }) {
                scheduledPosts[index] = updated
            }
            await NotificationService.shared.cancelPostReminder(postId: updated.id)
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Calendar ↔ Scheduled Post Sync

    func updateCalendarItemWithSync(_ item: ContentCalendarItem) async throws -> ContentCalendarItem {
        guard !isDemoMode else { throw CloudKitError.operationFailed(HubMessages.demoReadOnly) }
        let saved = try await cloudKitService.saveCalendarItem(item)
        if let index = calendarItems.firstIndex(where: { $0.id == saved.id }) {
            calendarItems[index] = saved
        } else {
            calendarItems.append(saved)
        }

        if let post = scheduledPosts.first(where: { $0.calendarItemId == saved.id }) {
            var updated = post
            updated.platform = saved.platform
            updated.content = saved.notes.isEmpty ? saved.title : "\(saved.title)\n\n\(saved.notes)"
            updated.scheduledDate = saved.date
            let savedPost = try await socialMediaService.saveScheduledPost(updated)
            if let postIndex = scheduledPosts.firstIndex(where: { $0.id == savedPost.id }) {
                scheduledPosts[postIndex] = savedPost
            }
            if savedPost.status == .scheduled || savedPost.status == .readyForReview {
                try? await NotificationService.shared.schedulePostReminder(for: savedPost)
            }
        }
        return saved
    }

    func deleteCalendarItemWithSync(_ item: ContentCalendarItem) async throws {
        guard !isDemoMode else { throw CloudKitError.operationFailed(HubMessages.demoReadOnly) }
        let recordID = CKRecord.ID(recordName: item.id)
        _ = try await cloudKitService.privateDB.deleteRecord(withID: recordID)
        calendarItems.removeAll { $0.id == item.id }

        if let post = scheduledPosts.first(where: { $0.calendarItemId == item.id }) {
            try? await socialMediaService.deleteScheduledPost(post)
            await NotificationService.shared.cancelPostReminder(postId: post.id)
            scheduledPosts.removeAll { $0.id == post.id }
        }
    }

    func deleteCalendarItemsWithSync(_ items: [ContentCalendarItem]) async -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        for item in items {
            do {
                try await deleteCalendarItemWithSync(item)
                deleted += 1
            } catch {
                failed += 1
            }
        }
        return (deleted, failed)
    }

    func scheduleHooksFromCampaignPlan(_ plan: CampaignPlan, startDate: Date, spacingDays: Int = 1) async throws -> Int {
        let hooks = CampaignPlanParser.hookIdeas(from: plan.outlineDetails)
        guard !hooks.isEmpty else {
            throw CloudKitError.operationFailed("No hook ideas found in this plan.")
        }
        var date = startDate
        var scheduled = 0
        let platform = MarketingPlatform(rawValue: plan.platform) ?? .instagram

        for hook in hooks.prefix(5) {
            guard canAddCalendarItem() else {
                if scheduled == 0 { throw CloudKitError.operationFailed("Calendar limit reached for your plan.") }
                break
            }
            try await scheduleContent(
                title: "Campaign: \(String(hook.prefix(40)))",
                content: hook,
                platform: platform,
                date: date,
                enableReminder: true
            )
            scheduled += 1
            date = Calendar.current.date(byAdding: .day, value: spacingDays, to: date) ?? date
        }
        return scheduled
    }

    func snoozeScheduledPost(postId: String, by interval: TimeInterval) async {
        guard let post = scheduledPosts.first(where: { $0.id == postId }) else { return }
        let newDate = Date().addingTimeInterval(interval)
        var updated = post
        updated.scheduledDate = newDate
        updated.status = .scheduled
        do {
            let saved = try await socialMediaService.saveScheduledPost(updated)
            if let index = scheduledPosts.firstIndex(where: { $0.id == saved.id }) {
                scheduledPosts[index] = saved
            }
            if let calendarItemId = saved.calendarItemId,
               let item = calendarItems.first(where: { $0.id == calendarItemId }) {
                let updatedItem = ContentCalendarItem(
                    id: item.id,
                    userId: item.userId,
                    brandId: item.brandId,
                    date: newDate,
                    platform: item.platform,
                    title: item.title,
                    notes: item.notes
                )
                _ = try? await updateCalendarItemWithSync(updatedItem)
            } else {
                try? await NotificationService.shared.schedulePostReminder(for: saved)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentPaywallIfNeededForCalendar() -> Bool {
        guard !canAddCalendarItem() else { return false }
        showPaywall = true
        return true
    }

    func presentPaywallIfNeededForCampaign() -> Bool {
        guard !canAddCampaignPlan() else { return false }
        showPaywall = true
        return true
    }

    var overduePosts: [ScheduledPost] {
        let now = Date()
        return scheduledPosts.filter { post in
            (post.status == .scheduled || post.status == .readyForReview) && post.scheduledDate < now
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var shareCompletionRate: Double {
        let relevant = scheduledPosts.filter { post in
            post.status == .shared || post.status == .posted ||
            post.status == .readyForReview || post.status == .scheduled
        }
        guard !relevant.isEmpty else { return 0 }
        let shared = relevant.filter { $0.status == .shared || $0.status == .posted }.count
        return Double(shared) / Double(relevant.count)
    }

    var daysWithEmptySchedule: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (1...3).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let hasItems = calendarItems.contains { calendar.isDate($0.date, inSameDayAs: day) }
            return hasItems ? nil : day
        }
    }

    func linkedScheduledPost(for calendarItemId: String) -> ScheduledPost? {
        scheduledPosts.first { $0.calendarItemId == calendarItemId }
    }

    var readyToSharePosts: [ScheduledPost] {
        let now = Date()
        return scheduledPosts.filter { post in
            post.status == .readyForReview ||
            (post.status == .scheduled && post.scheduledDate <= now)
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var todaysCalendarItems: [ContentCalendarItem] {
        calendarItems
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    var planningStreakDays: Int {
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        let scheduledDays = Set(calendarItems.map { calendar.startOfDay(for: $0.date) })
        while scheduledDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
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
        PostScheduler.shared.stopScheduling()
        authService.signOut()
        isDemoMode = false
        didBootstrap = false
        userProfile = nil
        brands = []
        campaignPlans = []
        calendarItems = []
        scheduledPosts = []
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
