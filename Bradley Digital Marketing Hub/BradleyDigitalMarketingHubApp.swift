import SwiftUI
import UserNotifications

// MARK: - Temporary NotificationService (until Xcode recognizes separate file)
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func schedulePostReminder(for post: ScheduledPost) async throws {
        // Stub implementation - full version in NotificationService.swift
    }
    
    func registerNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        let reviewAction = UNNotificationAction(
            identifier: "REVIEW_POST",
            title: "Review Post",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "POST_REMINDER",
            actions: [reviewAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }
    
    static func handleNotification(userInfo: [AnyHashable: Any]) -> String? {
        guard let type = userInfo["type"] as? String,
              type == "scheduledPost",
              let postId = userInfo["postId"] as? String else {
            return nil
        }
        return postId
    }
}

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
                    // Register notification categories when app launches
                    NotificationService.shared.registerNotificationCategories()
                }
        }
    }
}

// MARK: - Orientation Support
extension UIApplication {
    static var supportedOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Support all orientations
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let postId = NotificationService.handleNotification(userInfo: userInfo) {
            // Post notification to open post review
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenPostReview"),
                object: nil,
                userInfo: ["postId": postId]
            )
        }
        
        completionHandler()
    }
}
