import Foundation
import CloudKit

enum SocialMediaError: LocalizedError {
    case directPostingUnavailable
    case accountConnectionUnavailable

    var errorDescription: String? {
        switch self {
        case .directPostingUnavailable:
            return "Direct API posting is not available yet. Use the Share Sheet to publish manually from a post reminder."
        case .accountConnectionUnavailable:
            return "Direct account connections are not available yet. Schedule posts and share them manually when reminded."
        }
    }
}

/// Manages scheduled posts, reminders, and manual sharing — no mock OAuth or auto-posting.
@MainActor
final class SocialMediaService {
    private let cloudKitService: CloudKitService

    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }

    // MARK: - Account Management

    func fetchConnectedAccounts(userId: String) async throws -> [ConnectedSocialAccount] {
        let predicate = NSPredicate(format: "userId == %@", userId)
        return try await cloudKitService.fetch(
            recordType: ConnectedSocialAccount.recordType,
            predicate: predicate,
            scope: .private,
            sortDescriptors: [NSSortDescriptor(key: "connectedAt", ascending: false)]
        )
    }

    func saveConnectedAccount(_ account: ConnectedSocialAccount) async throws -> ConnectedSocialAccount {
        try await cloudKitService.save(account, scope: .private)
    }

    func disconnectAccount(_ account: ConnectedSocialAccount) async throws {
        var updated = account
        updated.isActive = false
        _ = try await saveConnectedAccount(updated)
    }

    /// Removes legacy placeholder account records created before manual-share-only workflow.
    func removeLegacyPlaceholderAccount(_ account: ConnectedSocialAccount) async throws {
        let recordID = CKRecord.ID(recordName: account.id)
        _ = try await cloudKitService.privateDB.deleteRecord(withID: recordID)
    }

    // MARK: - Scheduled Posts

    func fetchScheduledPosts(userId: String, status: PostStatus? = nil) async throws -> [ScheduledPost] {
        var predicate: NSPredicate
        if let status = status {
            predicate = NSPredicate(format: "userId == %@ AND status == %@", userId, status.rawValue)
        } else {
            predicate = NSPredicate(format: "userId == %@", userId)
        }
        return try await cloudKitService.fetch(
            recordType: ScheduledPost.recordType,
            predicate: predicate,
            scope: .private,
            sortDescriptors: [NSSortDescriptor(key: "scheduledDate", ascending: true)]
        )
    }

    func fetchPostsDueNow(userId: String) async throws -> [ScheduledPost] {
        let now = Date()
        let predicate = NSPredicate(
            format: "userId == %@ AND status == %@ AND scheduledDate <= %@",
            userId, PostStatus.scheduled.rawValue, now as NSDate
        )
        return try await cloudKitService.fetch(
            recordType: ScheduledPost.recordType,
            predicate: predicate,
            scope: .private,
            sortDescriptors: [NSSortDescriptor(key: "scheduledDate", ascending: true)]
        )
    }

    func saveScheduledPost(_ post: ScheduledPost) async throws -> ScheduledPost {
        try await cloudKitService.save(post, scope: .private)
    }

    func deleteScheduledPost(_ post: ScheduledPost) async throws {
        let recordID = CKRecord.ID(recordName: post.id)
        _ = try await cloudKitService.privateDB.deleteRecord(withID: recordID)
    }

    func updatePostStatus(_ post: ScheduledPost, status: PostStatus, errorMessage: String? = nil) async throws -> ScheduledPost {
        var updated = post
        updated.status = status
        if status == .posted || status == .shared {
            updated.postedAt = Date()
        }
        updated.errorMessage = errorMessage
        return try await saveScheduledPost(updated)
    }

    // MARK: - Posting (unavailable — manual share only)

    func postToPlatform(
        _ platform: SocialPlatform,
        account: ConnectedSocialAccount,
        content: String,
        mediaURLs: [URL] = [],
        hashtags: String? = nil,
        linkURL: String? = nil
    ) async throws -> String {
        throw SocialMediaError.directPostingUnavailable
    }

    // MARK: - Reminder Processing

    /// Marks due posts as ready for review and sends local reminders for manual sharing.
    func processScheduledPosts(userId: String) async {
        do {
            let postsDue = try await fetchPostsDueNow(userId: userId)

            for post in postsDue {
                let updated = try await updatePostStatus(post, status: .readyForReview)
                try? await NotificationService.shared.schedulePostReminder(for: updated)
            }
        } catch {
            print("Error processing scheduled posts: \(error.localizedDescription)")
        }
    }

    func connectAccount(for platform: SocialPlatform, userId: String) async throws -> ConnectedSocialAccount {
        throw SocialMediaError.accountConnectionUnavailable
    }

    func sharePost(content: String, platform: SocialPlatform, linkURL: String? = nil) {
        PlatformShareHelper.shareToPlatform(platform, content: content, linkURL: linkURL)
    }
}

protocol SocialPlatformOAuth {
    func initiateOAuth(for platform: SocialPlatform) async throws -> String
    func handleOAuthCallback(url: URL) async throws -> (accountId: String, accessToken: String, refreshToken: String?)
    func refreshAccessToken(for account: ConnectedSocialAccount) async throws -> String
}
