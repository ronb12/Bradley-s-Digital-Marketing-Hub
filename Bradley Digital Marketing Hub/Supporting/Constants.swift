import Foundation
import SwiftUI

enum AppConstants {
    /// Update with your iCloud container identifier in CloudKit Dashboard.
    static let cloudKitContainerIdentifier = "iCloud.com.example.BradleyDigitalMarketingHub"
    static let marketingSupportEmail = "support@bradleyvirtualsolutions.com"
}

enum DemoContent {
    static let defaultAffiliateURL: URL = {
        // This should always be valid, but we'll provide a fallback
        guard let url = URL(string: "https://developer.apple.com") else {
            // Fallback to a safe default
            return URL(string: "https://apple.com")!
        }
        return url
    }()
}

extension Color {
    // Legacy colors - now use ThemeManager for theme-aware colors
    static let hubBlue = Color(red: 51/255, green: 128/255, blue: 1)
    static let hubBackground = Color(UIColor.systemGroupedBackground)
    
    // Theme-aware colors will be accessed via ThemeManager in views
}
