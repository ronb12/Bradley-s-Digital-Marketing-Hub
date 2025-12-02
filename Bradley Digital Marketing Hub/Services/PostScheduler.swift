import Foundation
import BackgroundTasks
import UIKit

/// Handles background scheduling and automatic posting of scheduled social media posts
@MainActor
final class PostScheduler {
    static let shared = PostScheduler()
    
    private let socialMediaService: SocialMediaService
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var timer: Timer?
    
    private init() {
        // Initialize with a default service - will be updated by AppViewModel
        self.socialMediaService = SocialMediaService(cloudKitService: CloudKitService())
    }
    
    func setSocialMediaService(_ service: SocialMediaService) {
        // This allows AppViewModel to inject its instance
        // Note: In Swift, we'd typically use dependency injection, but since we need a singleton pattern,
        // we'll work with the service passed from AppViewModel
    }
    
    /// Start the scheduler to periodically check for posts due
    func startScheduling(socialMediaService: SocialMediaService, userId: String) {
        stopScheduling()
        
        // Check for posts immediately
        Task {
            await processScheduledPosts(service: socialMediaService, userId: userId)
        }
        
        // Set up a timer to check every 5 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.processScheduledPosts(service: socialMediaService, userId: userId)
            }
        }
    }
    
    /// Stop the scheduler
    func stopScheduling() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Process scheduled posts that are due
    private func processScheduledPosts(service: SocialMediaService, userId: String) async {
        // Register background task to ensure we can complete even if app goes to background
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            if let taskID = self?.backgroundTaskID {
                UIApplication.shared.endBackgroundTask(taskID)
                self?.backgroundTaskID = .invalid
            }
        }
        
        guard backgroundTaskID != .invalid else { return }
        
        do {
            await service.processScheduledPosts(userId: userId)
        } catch {
            print("Error processing scheduled posts: \(error.localizedDescription)")
        }
        
        // End the background task
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    /// Register background processing task (for iOS background tasks)
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.bradleydigitalmarketinghub.postscheduler",
            using: nil
        ) { task in
            self.handleBackgroundTask(task: task as! BGProcessingTask)
        }
    }
    
    /// Schedule the next background task
    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: "com.bradleydigitalmarketinghub.postscheduler")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 300) // 5 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error.localizedDescription)")
        }
    }
    
    /// Handle background task execution
    private func handleBackgroundTask(task: BGProcessingTask) {
        // Schedule the next background task
        scheduleBackgroundTask()
        
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Process posts
        Task {
            // Note: We need userId from somewhere - could store in UserDefaults or fetch from CloudKit
            // For now, this is a placeholder
            if let userId = UserDefaults.standard.string(forKey: "BradleyDigitalMarketingHub.lastAppleUserId") {
                let service = SocialMediaService(cloudKitService: CloudKitService())
                await service.processScheduledPosts(userId: userId)
                task.setTaskCompleted(success: true)
            } else {
                task.setTaskCompleted(success: false)
            }
        }
    }
}

