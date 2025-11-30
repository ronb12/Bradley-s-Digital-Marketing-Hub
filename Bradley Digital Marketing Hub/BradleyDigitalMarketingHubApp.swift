import SwiftUI

@main
struct BradleyDigitalMarketingHubApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .environmentObject(appViewModel.subscriptionManager)
        }
    }
}
