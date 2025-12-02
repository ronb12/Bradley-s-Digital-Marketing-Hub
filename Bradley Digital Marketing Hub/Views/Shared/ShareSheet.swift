import SwiftUI
import UIKit

/// Native iOS share sheet that allows sharing content to social media apps
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    
    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Platform-specific share functionality using URL schemes
struct PlatformShareHelper {
    
    /// Get URL for sharing to a specific platform
    static func shareURL(for platform: SocialPlatform, content: String, linkURL: String? = nil) -> URL? {
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedURL = (linkURL ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        switch platform {
        case .twitter:
            // Twitter web intent - works even if app not installed
            if let linkURL = linkURL, !linkURL.isEmpty {
                return URL(string: "https://twitter.com/intent/tweet?text=\(encodedContent)&url=\(encodedURL)")
            } else {
                return URL(string: "https://twitter.com/intent/tweet?text=\(encodedContent)")
            }
            
        case .facebook:
            // Facebook share dialog
            if let linkURL = linkURL, !linkURL.isEmpty {
                return URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(encodedURL)&quote=\(encodedContent)")
            } else {
                return URL(string: "https://www.facebook.com/sharer/sharer.php?quote=\(encodedContent)")
            }
            
        case .linkedin:
            // LinkedIn share
            if let linkURL = linkURL, !linkURL.isEmpty {
                return URL(string: "https://www.linkedin.com/sharing/share-offsite/?url=\(encodedURL)&summary=\(encodedContent)")
            } else {
                return URL(string: "https://www.linkedin.com/sharing/share-offsite/?summary=\(encodedContent)")
            }
            
        case .pinterest:
            // Pinterest pin
            if let linkURL = linkURL, !linkURL.isEmpty {
                return URL(string: "https://www.pinterest.com/pin/create/button/?url=\(encodedURL)&description=\(encodedContent)")
            } else {
                return URL(string: "https://www.pinterest.com/pin/create/button/?description=\(encodedContent)")
            }
            
        case .instagram, .tiktok:
            // Instagram and TikTok don't support URL schemes for posting
            // User would need to copy content and paste manually
            return nil
        }
    }
    
    /// Open share dialog for a specific platform
    static func shareToPlatform(_ platform: SocialPlatform, content: String, linkURL: String? = nil) {
        if let url = shareURL(for: platform, content: content, linkURL: linkURL) {
            UIApplication.shared.open(url)
        } else {
            // For platforms without URL schemes, use native share sheet
            let items: [Any] = [content] + (linkURL.flatMap { [URL(string: $0)] }.compactMap { $0 } ?? [])
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let shareSheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
                rootViewController.present(shareSheet, animated: true)
            }
        }
    }
}

