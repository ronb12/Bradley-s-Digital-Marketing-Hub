import Foundation

@MainActor
final class ContentGeneratorViewModel: ObservableObject {
    @Published var businessType: String = ""
    @Published var audience: String = ""
    @Published var tone: MarketingTone = .friendly
    @Published var platform: MarketingPlatform = .instagram
    @Published var generatedContent: [String] = []
    @Published var isSaving = false
    @Published var statusMessage: String?

    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func generate() {
        let base = "For \(businessType.isEmpty ? "any" : businessType) brands targeting \(audience.isEmpty ? "their audience" : audience), focus on \(tone.rawValue.lowercased()) storytelling on \(platform.rawValue)."
        generatedContent = (1...3).map { index in
            "Idea #\(index): \(base) CTA idea \(index)."
        }
    }

    func saveToCalendar(text: String, userId: String, brandId: String?) async {
        guard !text.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        let item = ContentCalendarItem(
            userId: userId,
            brandId: brandId,
            date: Date(),
            platform: platform.rawValue,
            title: "Generated Content",
            notes: text
        )
        do {
            _ = try await service.saveCalendarItem(item)
            statusMessage = "Saved to marketing calendar."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
