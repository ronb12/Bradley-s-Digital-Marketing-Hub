import Foundation

@MainActor
final class ContentCalendarViewModel: ObservableObject {
    @Published var platform: MarketingPlatform = .instagram
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var date: Date = Date()
    @Published var statusMessage: String?
    @Published var isSaving = false
    @Published var enableReminder = false

    private let service: CloudKitService
    private let socialMediaService: SocialMediaService
    @Published var connectedAccounts: [ConnectedSocialAccount] = []

    init(service: CloudKitService, socialMediaService: SocialMediaService? = nil) {
        self.service = service
        self.socialMediaService = socialMediaService ?? SocialMediaService(cloudKitService: service)
    }
    
    func loadAccounts(userId: String) async {
        // No longer needed for reminder-based flow, but keeping for future use
        do {
            connectedAccounts = try await socialMediaService.fetchConnectedAccounts(userId: userId)
        } catch {
            // Silent fail - accounts not required for reminders
        }
    }

    func addItem(userId: String, brandId: String?, currentCount: Int, tier: SubscriptionTier) async {
        if let limit = tier.maxCalendarItems, currentCount >= limit {
            statusMessage = "Free tier allows up to 10 items."
            return
        }
        guard !title.isEmpty else {
            statusMessage = "Provide a title for the calendar entry."
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        // Save calendar item
        let item = ContentCalendarItem(
            userId: userId,
            brandId: brandId,
            date: date,
            platform: platform.rawValue,
            title: title,
            notes: notes
        )
        
        do {
            let savedItem = try await service.saveCalendarItem(item)
            
            // If reminder is enabled, create a scheduled post for review
            if enableReminder {
                let scheduledPost = ScheduledPost(
                    userId: userId,
                    brandId: brandId,
                    calendarItemId: savedItem.id,
                    platform: platform.rawValue,
                    accountId: nil, // Not needed for manual sharing
                    content: notes.isEmpty ? title : "\(title)\n\n\(notes)",
                    scheduledDate: date,
                    status: .scheduled
                )
                let savedPost = try await socialMediaService.saveScheduledPost(scheduledPost)
                
                // Schedule notification reminder
                try? await NotificationService.shared.schedulePostReminder(for: savedPost)
                
                statusMessage = "Content scheduled. You'll be reminded to review and share at the scheduled time."
            } else {
                statusMessage = "Content scheduled."
            }
            
            title = ""
            notes = ""
            enableReminder = false
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
