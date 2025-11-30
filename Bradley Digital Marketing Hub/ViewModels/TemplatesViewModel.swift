import Foundation

@MainActor
final class TemplatesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedTemplate: TemplateItem?

    func filteredTemplates(_ templates: [TemplateItem], tier: SubscriptionTier) -> [TemplateItem] {
        let available = templates.availableTemplates(for: tier)
        guard !searchText.isEmpty else { return available }
        return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func isLocked(_ template: TemplateItem, tier: SubscriptionTier) -> Bool {
        if template.isAgencyOnly {
            return tier != .agency
        }
        if template.isPremium {
            return tier == .free
        }
        return false
    }
}
