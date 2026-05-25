import Foundation

@MainActor
final class TemplatesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedTemplate: TemplateItem?

    func filteredTemplates(_ templates: [TemplateItem], tier: SubscriptionTier) -> [TemplateItem] {
        let base = templates.sorted { lhs, rhs in
            if isLocked(lhs, tier: tier) != isLocked(rhs, tier: tier) {
                return !isLocked(lhs, tier: tier)
            }
            return lhs.name < rhs.name
        }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
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
