import Foundation
import CloudKit

// MARK: - Social Media Account Connection

enum SocialPlatform: String, CaseIterable, Identifiable, Hashable {
    case instagram = "Instagram"
    case facebook = "Facebook"
    case linkedin = "LinkedIn"
    case twitter = "Twitter/X"
    case tiktok = "TikTok"
    case pinterest = "Pinterest"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .instagram: return "camera.fill"
        case .facebook: return "f.circle.fill"
        case .linkedin: return "network"
        case .twitter: return "at"
        case .tiktok: return "music.note"
        case .pinterest: return "pin.fill"
        }
    }
    
    var requiresMedia: Bool {
        switch self {
        case .instagram, .pinterest: return true
        case .facebook, .linkedin, .twitter, .tiktok: return false
        }
    }
    
    var maxPostLength: Int {
        switch self {
        case .twitter: return 280
        case .instagram: return 2200
        case .facebook: return 63206
        case .linkedin: return 3000
        case .tiktok: return 2200
        case .pinterest: return 500
        }
    }
}

struct ConnectedSocialAccount: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "ConnectedSocialAccount"
    
    var id: String
    var userId: String
    var platform: String
    var accountName: String
    var accountId: String // Platform-specific account ID
    var isActive: Bool
    var connectedAt: Date
    var accessToken: String? // Encrypted/stored securely
    var refreshToken: String?
    
    init(id: String = UUID().uuidString,
         userId: String,
         platform: String,
         accountName: String,
         accountId: String,
         isActive: Bool = true,
         connectedAt: Date = Date(),
         accessToken: String? = nil,
         refreshToken: String? = nil) {
        self.id = id
        self.userId = userId
        self.platform = platform
        self.accountName = accountName
        self.accountId = accountId
        self.isActive = isActive
        self.connectedAt = connectedAt
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let platform = record["platform"] as? String,
              let accountName = record["accountName"] as? String,
              let accountId = record["accountId"] as? String,
              let connectedAt = record["connectedAt"] as? Date else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.userId = userId
        self.platform = platform
        self.accountName = accountName
        self.accountId = accountId
        self.isActive = record["isActive"] as? Int == 1
        self.connectedAt = connectedAt
        self.accessToken = record["accessToken"] as? String
        self.refreshToken = record["refreshToken"] as? String
    }
    
    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }
    
    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["platform"] = platform as CKRecordValue
        record["accountName"] = accountName as CKRecordValue
        record["accountId"] = accountId as CKRecordValue
        record["isActive"] = (isActive ? 1 : 0) as CKRecordValue
        record["connectedAt"] = connectedAt as CKRecordValue
        record["accessToken"] = accessToken as CKRecordValue?
        record["refreshToken"] = refreshToken as CKRecordValue?
    }
}

// MARK: - Scheduled Post with Auto-Post Support

enum PostStatus: String, Codable {
    case draft = "Draft"
    case scheduled = "Scheduled"
    case readyForReview = "Ready for Review"
    case reviewed = "Reviewed"
    case shared = "Shared"
    case cancelled = "Cancelled"
}

struct ScheduledPost: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "ScheduledPost"
    
    var id: String
    var userId: String
    var brandId: String?
    var calendarItemId: String? // Links to ContentCalendarItem
    var platform: String
    var accountId: String? // ConnectedSocialAccount ID
    var content: String
    var scheduledDate: Date
    var status: PostStatus
    var mediaURLs: [String] // URLs to images/videos stored in CloudKit
    var hashtags: String?
    var linkURL: String?
    var postedAt: Date?
    var errorMessage: String?
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         brandId: String? = nil,
         calendarItemId: String? = nil,
         platform: String,
         accountId: String? = nil,
         content: String,
         scheduledDate: Date,
         status: PostStatus = .scheduled,
         mediaURLs: [String] = [],
         hashtags: String? = nil,
         linkURL: String? = nil,
         postedAt: Date? = nil,
         errorMessage: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.brandId = brandId
        self.calendarItemId = calendarItemId
        self.platform = platform
        self.accountId = accountId
        self.content = content
        self.scheduledDate = scheduledDate
        self.status = status
        self.mediaURLs = mediaURLs
        self.hashtags = hashtags
        self.linkURL = linkURL
        self.postedAt = postedAt
        self.errorMessage = errorMessage
        self.createdAt = createdAt
    }
    
    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let platform = record["platform"] as? String,
              let content = record["content"] as? String,
              let scheduledDate = record["scheduledDate"] as? Date,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.userId = userId
        self.brandId = record["brandId"] as? String
        self.calendarItemId = record["calendarItemId"] as? String
        self.platform = platform
        self.accountId = record["accountId"] as? String
        self.content = content
        self.scheduledDate = scheduledDate
        if let statusString = record["status"] as? String,
           let status = PostStatus(rawValue: statusString) {
            self.status = status
        } else {
            self.status = .scheduled
        }
        self.mediaURLs = record["mediaURLs"] as? [String] ?? []
        self.hashtags = record["hashtags"] as? String
        self.linkURL = record["linkURL"] as? String
        self.postedAt = record["postedAt"] as? Date
        self.errorMessage = record["errorMessage"] as? String
        self.createdAt = createdAt
    }
    
    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }
    
    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["brandId"] = brandId as CKRecordValue?
        record["calendarItemId"] = calendarItemId as CKRecordValue?
        record["platform"] = platform as CKRecordValue
        record["accountId"] = accountId as CKRecordValue?
        record["content"] = content as CKRecordValue
        record["scheduledDate"] = scheduledDate as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["mediaURLs"] = mediaURLs as CKRecordValue
        record["hashtags"] = hashtags as CKRecordValue?
        record["linkURL"] = linkURL as CKRecordValue?
        record["postedAt"] = postedAt as CKRecordValue?
        record["errorMessage"] = errorMessage as CKRecordValue?
        record["createdAt"] = createdAt as CKRecordValue
    }
}

