import Foundation
import CloudKit

// MARK: - Subscription & Feature Flags

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case free
    case pro
    case agency

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .agency: return "Agency"
        }
    }

    var productIdentifier: String? {
        switch self {
        case .free:
            return nil
        case .pro:
            return "dmhub.pro.monthly" // Update if App Store Connect IDs change
        case .agency:
            return "dmhub.agency.monthly" // Update if App Store Connect IDs change
        }
    }

    var accentColorHex: String {
        switch self {
        case .free: return "#5B8DEF"
        case .pro: return "#2AA876"
        case .agency: return "#7F52FF"
        }
    }

    var maxCampaignPlans: Int? {
        switch self {
        case .free: return 3
        case .pro, .agency: return nil
        }
    }

    var maxCalendarItems: Int? {
        switch self {
        case .free: return 10
        case .pro, .agency: return nil
        }
    }

    var maxBrands: Int {
        switch self {
        case .free, .pro: return 1
        case .agency: return 10
        }
    }

    var canAccessAgencyOnlyTemplates: Bool {
        self == .agency
    }
}

enum MarketingTone: String, CaseIterable, Identifiable {
    case friendly = "Friendly"
    case professional = "Professional"
    case luxury = "Luxury"
    case motivational = "Motivational"

    var id: String { rawValue }
}

enum MarketingPlatform: String, CaseIterable, Identifiable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case facebook = "Facebook"
    case youtube = "YouTube"
    case linkedin = "LinkedIn"
    case pinterest = "Pinterest"
    case email = "Email"

    var id: String { rawValue }
}

protocol CloudKitRecordConvertible {
    static var recordType: CKRecord.RecordType { get }
    var recordID: CKRecord.ID { get }

    init(record: CKRecord) throws
    func update(record: CKRecord)
}

extension CloudKitRecordConvertible {
    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        update(record: record)
        return record
    }
}

// MARK: - Models

struct UserProfile: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "UserProfile"

    var id: String { userId }
    var userId: String
    var name: String?
    var email: String?
    var businessName: String?
    var businessType: String?
    var plan: SubscriptionTier = .free
    var createdAt: Date
    var avatarAssetURL: URL?

    init(userId: String,
         name: String? = nil,
         email: String? = nil,
         businessName: String? = nil,
         businessType: String? = nil,
         plan: SubscriptionTier = .free,
         createdAt: Date = Date(),
         avatarAssetURL: URL? = nil) {
        self.userId = userId
        self.name = name
        self.email = email
        self.businessName = businessName
        self.businessType = businessType
        self.plan = plan
        self.createdAt = createdAt
        self.avatarAssetURL = avatarAssetURL
    }

    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.missingData
        }
        self.userId = userId
        self.name = record["name"] as? String
        self.email = record["email"] as? String
        self.businessName = record["businessName"] as? String
        self.businessType = record["businessType"] as? String
        if let planValue = record["plan"] as? String,
           let tier = SubscriptionTier(rawValue: planValue) {
            self.plan = tier
        } else {
            self.plan = .free
        }
        self.createdAt = createdAt
        if let asset = record["avatarAsset"] as? CKAsset {
            self.avatarAssetURL = asset.fileURL
        } else {
            self.avatarAssetURL = nil
        }
    }

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: userId)
    }

    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["name"] = name as CKRecordValue?
        record["email"] = email as CKRecordValue?
        record["businessName"] = businessName as CKRecordValue?
        record["businessType"] = businessType as CKRecordValue?
        record["plan"] = plan.rawValue as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
    }
}

struct Brand: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "Brand"

    var id: String
    var userId: String
    var name: String
    var industry: String
    var colorHex: String

    init(id: String = UUID().uuidString, userId: String, name: String, industry: String, colorHex: String) {
        self.id = id
        self.userId = userId
        self.name = name
        self.industry = industry
        self.colorHex = colorHex
    }

    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let name = record["name"] as? String,
              let industry = record["industry"] as? String,
              let colorHex = record["colorHex"] as? String else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.userId = userId
        self.name = name
        self.industry = industry
        self.colorHex = colorHex
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["name"] = name as CKRecordValue
        record["industry"] = industry as CKRecordValue
        record["colorHex"] = colorHex as CKRecordValue
    }
}

struct CampaignPlan: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "CampaignPlan"

    var id: String
    var userId: String
    var brandId: String?
    var platform: String
    var budget: Double
    var goal: String
    var outlineDetails: String
    var createdAt: Date

    init(id: String = UUID().uuidString,
         userId: String,
         brandId: String? = nil,
         platform: String,
         budget: Double,
         goal: String,
         outlineDetails: String,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.brandId = brandId
        self.platform = platform
        self.budget = budget
        self.goal = goal
        self.outlineDetails = outlineDetails
        self.createdAt = createdAt
    }

    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let platform = record["platform"] as? String,
              let goal = record["goal"] as? String,
              let outlineDetails = record["outlineDetails"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.userId = userId
        self.brandId = record["brandId"] as? String
        self.platform = platform
        self.budget = record["budget"] as? Double ?? 0
        self.goal = goal
        self.outlineDetails = outlineDetails
        self.createdAt = createdAt
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["brandId"] = brandId as CKRecordValue?
        record["platform"] = platform as CKRecordValue
        record["budget"] = budget as CKRecordValue
        record["goal"] = goal as CKRecordValue
        record["outlineDetails"] = outlineDetails as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
    }
}

struct ContentCalendarItem: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "ContentCalendarItem"

    var id: String
    var userId: String
    var brandId: String?
    var date: Date
    var platform: String
    var title: String
    var notes: String

    init(id: String = UUID().uuidString,
         userId: String,
         brandId: String? = nil,
         date: Date,
         platform: String,
         title: String,
         notes: String) {
        self.id = id
        self.userId = userId
        self.brandId = brandId
        self.date = date
        self.platform = platform
        self.title = title
        self.notes = notes
    }

    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let date = record["date"] as? Date,
              let platform = record["platform"] as? String,
              let title = record["title"] as? String,
              let notes = record["notes"] as? String else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.userId = userId
        self.brandId = record["brandId"] as? String
        self.date = date
        self.platform = platform
        self.title = title
        self.notes = notes
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["brandId"] = brandId as CKRecordValue?
        record["date"] = date as CKRecordValue
        record["platform"] = platform as CKRecordValue
        record["title"] = title as CKRecordValue
        record["notes"] = notes as CKRecordValue
    }
}

struct TemplateItem: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "Template"

    var id: String
    var name: String
    var description: String
    var isPremium: Bool
    var isAgencyOnly: Bool
    var assetFileName: String?

    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         isPremium: Bool,
         isAgencyOnly: Bool,
         assetFileName: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.isPremium = isPremium
        self.isAgencyOnly = isAgencyOnly
        self.assetFileName = assetFileName
    }

    init(record: CKRecord) throws {
        guard let name = record["name"] as? String,
              let description = record["description"] as? String,
              let isPremium = record["isPremium"] as? Int,
              let isAgencyOnly = record["isAgencyOnly"] as? Int else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.name = name
        self.description = description
        self.isPremium = isPremium == 1
        self.isAgencyOnly = isAgencyOnly == 1
        if let asset = record["fileAsset"] as? CKAsset {
            self.assetFileName = asset.fileURL?.lastPathComponent
        }
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    func update(record: CKRecord) {
        record["name"] = name as CKRecordValue
        record["description"] = description as CKRecordValue
        record["isPremium"] = (isPremium ? 1 : 0) as CKRecordValue
        record["isAgencyOnly"] = (isAgencyOnly ? 1 : 0) as CKRecordValue
        // Attach assets via CKAsset upload pipeline as needed
    }
}

struct AffiliateTool: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "AffiliateTool"

    var id: String
    var name: String
    var shortDescription: String
    var url: String
    var isProRecommended: Bool

    init(id: String = UUID().uuidString,
         name: String,
         shortDescription: String,
         url: String,
         isProRecommended: Bool) {
        self.id = id
        self.name = name
        self.shortDescription = shortDescription
        self.url = url
        self.isProRecommended = isProRecommended
    }

    init(record: CKRecord) throws {
        guard let name = record["name"] as? String,
              let shortDescription = record["shortDescription"] as? String,
              let url = record["url"] as? String,
              let isProRecommended = record["isProRecommended"] as? Int else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.name = name
        self.shortDescription = shortDescription
        self.url = url
        self.isProRecommended = isProRecommended == 1
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    func update(record: CKRecord) {
        record["name"] = name as CKRecordValue
        record["shortDescription"] = shortDescription as CKRecordValue
        record["url"] = url as CKRecordValue
        record["isProRecommended"] = (isProRecommended ? 1 : 0) as CKRecordValue
    }
}

struct AffiliateClick: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "AffiliateClick"

    var id: String
    var userId: String
    var toolId: String
    var timestamp: Date

    init(id: String = UUID().uuidString, userId: String, toolId: String, timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.toolId = toolId
        self.timestamp = timestamp
    }

    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let toolId = record["toolId"] as? String,
              let timestamp = record["timestamp"] as? Date else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.userId = userId
        self.toolId = toolId
        self.timestamp = timestamp
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["toolId"] = toolId as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
    }
}

struct Booking: Identifiable, Hashable, CloudKitRecordConvertible {
    static let recordType = "Booking"

    var id: String
    var userId: String
    var serviceType: String
    var requestedTime: Date
    var notes: String
    var createdAt: Date

    init(id: String = UUID().uuidString,
         userId: String,
         serviceType: String,
         requestedTime: Date,
         notes: String,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.serviceType = serviceType
        self.requestedTime = requestedTime
        self.notes = notes
        self.createdAt = createdAt
    }

    init(record: CKRecord) throws {
        guard let userId = record["userId"] as? String,
              let serviceType = record["serviceType"] as? String,
              let requestedTime = record["requestedTime"] as? Date,
              let notes = record["notes"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.missingData
        }
        self.id = record.recordID.recordName
        self.userId = userId
        self.serviceType = serviceType
        self.requestedTime = requestedTime
        self.notes = notes
        self.createdAt = createdAt
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    func update(record: CKRecord) {
        record["userId"] = userId as CKRecordValue
        record["serviceType"] = serviceType as CKRecordValue
        record["requestedTime"] = requestedTime as CKRecordValue
        record["notes"] = notes as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
    }
}

enum CloudKitError: LocalizedError {
    case missingData
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingData:
            return "The CloudKit record is missing required fields."
        case .operationFailed(let message):
            return message
        }
    }
}
