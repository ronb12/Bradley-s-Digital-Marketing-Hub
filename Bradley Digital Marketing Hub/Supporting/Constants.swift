import Foundation
import SwiftUI

enum AppConstants {
    /// Update with your iCloud container identifier in CloudKit Dashboard.
    static let cloudKitContainerIdentifier = "iCloud.com.example.BradleyDigitalMarketingHub"
    static let marketingSupportEmail = "support@bradleyvirtualsolutions.com"
}

enum DemoContent {
    static let defaultAffiliateURL = URL(string: "https://developer.apple.com")!
}

extension Color {
    static let hubBlue = Color(red: 51/255, green: 128/255, blue: 1)
    static let hubBackground = Color(UIColor.systemGroupedBackground)
}
