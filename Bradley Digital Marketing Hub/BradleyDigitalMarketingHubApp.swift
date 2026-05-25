import SwiftUI
import UserNotifications

@main
struct BradleyDigitalMarketingHubApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .environmentObject(appViewModel.subscriptionManager)
                .environmentObject(themeManager)
                .onAppear {
                    NotificationService.shared.registerNotificationCategories()
                    PostScheduler.shared.registerBackgroundTask()
                }
        }
    }
}

extension UIApplication {
    static var supportedOrientations: UIInterfaceOrientationMask {
        .all
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .all
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let postId = NotificationService.handleNotification(userInfo: userInfo) {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenPostReview"),
                object: nil,
                userInfo: ["postId": postId]
            )
        }

        completionHandler()
    }
}
