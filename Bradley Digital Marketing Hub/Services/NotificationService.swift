import Foundation
import UserNotifications

/// Service for managing notifications for scheduled posts
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Permission Management
    
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Post Reminder Notifications
    
    /// Schedule a notification to remind user about a scheduled post
    func schedulePostReminder(for post: ScheduledPost) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Check if notifications are authorized
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            print("Notifications not authorized, cannot schedule reminder for post \(post.id)")
            return
        }
        
        // Remove any existing notification for this post
        await cancelPostReminder(postId: post.id)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Review Your Post"
        content.body = "Your \(post.platform) post is scheduled for now. Review and share it!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "POST_REMINDER"
        content.userInfo = [
            "postId": post.id,
            "type": "scheduledPost"
        ]
        
        // Schedule notification at the scheduled time
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: post.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Use post ID as identifier for easy cancellation
        let request = UNNotificationRequest(
            identifier: "post-\(post.id)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
        print("Scheduled notification for post \(post.id) at \(post.scheduledDate)")
    }
    
    /// Cancel notification for a specific post
    func cancelPostReminder(postId: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["post-\(postId)"])
    }
    
    /// Cancel all post reminder notifications
    func cancelAllPostReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let postIdentifiers = pending.filter { $0.identifier.hasPrefix("post-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: postIdentifiers)
    }
    
    /// Reschedule all notifications for a user's scheduled posts
    func rescheduleAllReminders(userId: String, posts: [ScheduledPost], service: SocialMediaService) async {
        // Cancel all existing
        await cancelAllPostReminders()
        
        // Schedule notifications for posts that are scheduled and in the future
        let now = Date()
        for post in posts {
            // Only schedule for posts that are:
            // 1. Still scheduled (not shared/cancelled)
            // 2. In the future
            if post.status == .scheduled && post.scheduledDate > now {
                do {
                    try await schedulePostReminder(for: post)
                } catch {
                    print("Failed to schedule notification for post \(post.id): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Notification Categories & Actions
    
    func registerNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // Define actions for post reminder notifications
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
}

// MARK: - Notification Handling

extension NotificationService {
    /// Handle notification tap - should be called from AppDelegate/SceneDelegate
    static func handleNotification(userInfo: [AnyHashable: Any]) -> String? {
        guard let type = userInfo["type"] as? String,
              type == "scheduledPost",
              let postId = userInfo["postId"] as? String else {
            return nil
        }
        return postId
    }
}

