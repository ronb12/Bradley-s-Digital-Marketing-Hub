import Foundation

@MainActor
final class ContentCalendarViewModel: ObservableObject {
    @Published var platform: MarketingPlatform = .instagram
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var date: Date = Date()
    @Published var statusMessage: String?
    @Published var isSaving = false

    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
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
        let item = ContentCalendarItem(
            userId: userId,
            brandId: brandId,
            date: date,
            platform: platform.rawValue,
            title: title,
            notes: notes
        )
        do {
            _ = try await service.saveCalendarItem(item)
            statusMessage = "Content scheduled."
            title = ""
            notes = ""
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
