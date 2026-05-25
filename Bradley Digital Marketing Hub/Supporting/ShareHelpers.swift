import Foundation

extension MarketingPlatform {
    /// Best-effort map for platform-specific share URLs; nil → generic Share Sheet.
    var socialPlatform: SocialPlatform? {
        switch self {
        case .instagram: return .instagram
        case .facebook: return .facebook
        case .linkedin: return .linkedin
        case .tiktok: return .tiktok
        case .pinterest: return .pinterest
        default: return nil
        }
    }
}

enum ShareContentBuilder {
    static func fullText(content: String, hashtags: String? = nil) -> String {
        guard let hashtags, !hashtags.isEmpty else { return content }
        return "\(content)\n\n\(hashtags)"
    }

    static func shareItems(content: String, hashtags: String? = nil, linkURL: String? = nil) -> [Any] {
        var items: [Any] = [fullText(content: content, hashtags: hashtags)]
        if let linkURL, !linkURL.isEmpty, let url = URL(string: linkURL) {
            items.append(url)
        }
        return items
    }
}
