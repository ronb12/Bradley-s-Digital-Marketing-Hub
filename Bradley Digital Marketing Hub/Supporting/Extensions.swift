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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Temporary Stubs (until Xcode recognizes separate files)
import Foundation

enum PostStatus: String {
    case scheduled
}

struct ScheduledPost: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var userId: String
    var brandId: String?
    var calendarItemId: String?
    var platform: String
    var accountId: String?
    var content: String
    var scheduledDate: Date
    var status: PostStatus
    
    init(id: String = UUID().uuidString,
         userId: String,
         brandId: String? = nil,
         calendarItemId: String? = nil,
         platform: String,
         accountId: String? = nil,
         content: String,
         scheduledDate: Date,
         status: PostStatus) {
        self.id = id
        self.userId = userId
        self.brandId = brandId
        self.calendarItemId = calendarItemId
        self.platform = platform
        self.accountId = accountId
        self.content = content
        self.scheduledDate = scheduledDate
        self.status = status
    }
}

struct ConnectedSocialAccount: Identifiable, Hashable {
    var id: String
}

@MainActor
final class SocialMediaService {
    private let cloudKitService: CloudKitService
    
    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }
    
    func fetchConnectedAccounts(userId: String) async throws -> [ConnectedSocialAccount] {
        return []
    }
    
    func saveScheduledPost(_ post: ScheduledPost) async throws -> ScheduledPost {
        return post
    }
}

// MARK: - Temporary View Stubs
import SwiftUI

struct ScheduledPostsView: View {
    let service: SocialMediaService
    
    var body: some View {
        Text("Scheduled Posts")
    }
}

struct SocialAccountsView: View {
    let service: SocialMediaService
    
    var body: some View {
        Text("Social Accounts")
    }
}

struct PostReviewContainerView: View {
    let postId: String
    
    var body: some View {
        Text("Post Review")
    }
}
