import Foundation
import SwiftUI

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension DateComponentsFormatter {
    static let marketingDuration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .full
        return formatter
    }()
}

extension View {
    func primarySectionStyle() -> some View {
        padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

extension Array where Element == TemplateItem {
    func availableTemplates(for tier: SubscriptionTier) -> [TemplateItem] {
        filter { item in
            switch tier {
            case .free:
                return !item.isPremium && !item.isAgencyOnly
            case .pro:
                return !item.isAgencyOnly
            case .agency:
                return true
            }
        }
    }
}
