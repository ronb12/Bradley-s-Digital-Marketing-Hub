import Foundation
import UserNotifications
import CloudKit

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
    
    // MARK: - Booking Notifications
    
    /// Schedule notification for provider when a new booking is created
    func scheduleBookingNotification(for booking: Booking, providerName: String?) async throws {
        let center = UNUserNotificationCenter.current()
        
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            print("Notifications not authorized, cannot schedule booking notification")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "New Booking Received"
        content.body = "\(booking.userName ?? "A customer") booked \(booking.serviceType) for \(formatBookingDate(booking.requestedTime))"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "BOOKING_NOTIFICATION"
        content.userInfo = [
            "bookingId": booking.id,
            "type": "booking",
            "providerId": booking.providerId ?? ""
        ]
        
        // Schedule immediately (or with a small delay to ensure booking is saved)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "booking-\(booking.id)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
        print("Scheduled booking notification for booking \(booking.id)")
    }
    
    /// Schedule reminder notification for customer before their booking
    func scheduleBookingReminder(for booking: Booking, customerName: String?) async throws {
        let center = UNUserNotificationCenter.current()
        
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            return
        }
        
        // Schedule reminder 1 hour before booking time
        let reminderDate = booking.requestedTime.addingTimeInterval(-3600) // 1 hour before
        
        guard reminderDate > Date() else {
            // Booking is too soon, skip reminder
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Booking Reminder"
        content.body = "Your \(booking.serviceType) booking is in 1 hour"
        content.sound = .default
        content.categoryIdentifier = "BOOKING_REMINDER"
        content.userInfo = [
            "bookingId": booking.id,
            "type": "bookingReminder"
        ]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "booking-reminder-\(booking.id)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    private func formatBookingDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
        
        // Define actions for booking notifications
        let viewBookingAction = UNNotificationAction(
            identifier: "VIEW_BOOKING",
            title: "View Booking",
            options: [.foreground]
        )
        
        let postCategory = UNNotificationCategory(
            identifier: "POST_REMINDER",
            actions: [reviewAction],
            intentIdentifiers: [],
            options: []
        )
        
        let bookingCategory = UNNotificationCategory(
            identifier: "BOOKING_NOTIFICATION",
            actions: [viewBookingAction],
            intentIdentifiers: [],
            options: []
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: "BOOKING_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([postCategory, bookingCategory, reminderCategory])
    }
}

// MARK: - Notification Handling

extension NotificationService {
    /// Handle notification tap - should be called from AppDelegate/SceneDelegate
    static func handleNotification(userInfo: [AnyHashable: Any]) -> (type: String, id: String)? {
        guard let type = userInfo["type"] as? String else { return nil }
        
        if type == "scheduledPost", let postId = userInfo["postId"] as? String {
            return ("post", postId)
        } else if type == "booking", let bookingId = userInfo["bookingId"] as? String {
            return ("booking", bookingId)
        } else if type == "bookingReminder", let bookingId = userInfo["bookingId"] as? String {
            return ("bookingReminder", bookingId)
        }
        
        return nil
    }
}

