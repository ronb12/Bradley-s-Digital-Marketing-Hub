import Foundation
import BackgroundTasks
import UIKit

/// Checks for due scheduled posts and triggers manual-share reminders.
@MainActor
final class PostScheduler {
    static let shared = PostScheduler()

    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var timer: Timer?
    private var configuredService: SocialMediaService?

    private init() {}

    func configure(service: SocialMediaService) {
        configuredService = service
    }

    func startScheduling(socialMediaService: SocialMediaService, userId: String) {
        stopScheduling()
        configuredService = socialMediaService

        Task {
            await processScheduledPosts(service: socialMediaService, userId: userId)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let service = self.configuredService else { return }
                await self.processScheduledPosts(service: service, userId: userId)
            }
        }
    }

    func stopScheduling() {
        timer?.invalidate()
        timer = nil
    }

    private func processScheduledPosts(service: SocialMediaService, userId: String) async {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            if let taskID = self?.backgroundTaskID {
                UIApplication.shared.endBackgroundTask(taskID)
                self?.backgroundTaskID = .invalid
            }
        }

        guard backgroundTaskID != .invalid else { return }

        await service.processScheduledPosts(userId: userId)

        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.bradleydigitalmarketinghub.postscheduler",
            using: nil
        ) { task in
            self.handleBackgroundTask(task: task as! BGProcessingTask)
        }
    }

    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: "com.bradleydigitalmarketinghub.postscheduler")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 300)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error.localizedDescription)")
        }
    }

    private func handleBackgroundTask(task: BGProcessingTask) {
        scheduleBackgroundTask()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task { @MainActor in
            guard let userId = UserDefaults.standard.string(forKey: "BradleyDigitalMarketingHub.lastAppleUserId") else {
                task.setTaskCompleted(success: false)
                return
            }

            let service = configuredService ?? SocialMediaService(cloudKitService: CloudKitService())
            await service.processScheduledPosts(userId: userId)
            task.setTaskCompleted(success: true)
        }
    }
}
