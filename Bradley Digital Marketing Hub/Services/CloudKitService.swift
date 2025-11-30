import Foundation
import CloudKit

/// Wrapper around CloudKit with async/await helpers for all marketing records.
final class CloudKitService {
    private let container: CKContainer

    init(containerIdentifier: String = AppConstants.cloudKitContainerIdentifier) {
        self.container = CKContainer(identifier: containerIdentifier)
    }

    private var privateDB: CKDatabase { container.privateCloudDatabase }
    private var publicDB: CKDatabase { container.publicCloudDatabase }

    private func database(for scope: CKDatabase.Scope) -> CKDatabase {
        switch scope {
        case .`public`:
            return publicDB
        case .`private`:
            return privateDB
        case .shared:
            return container.sharedCloudDatabase
        @unknown default:
            return privateDB
        }
    }

    // MARK: - Generic Helpers

    private func save<T: CloudKitRecordConvertible>(_ item: T, scope: CKDatabase.Scope) async throws -> T {
        let record = item.makeRecord()
        let savedRecord = try await database(for: scope).save(record)
        return try T(record: savedRecord)
    }

    private func fetch<T: CloudKitRecordConvertible>(
        recordType: CKRecord.RecordType,
        predicate: NSPredicate = .init(value: true),
        scope: CKDatabase.Scope,
        sortDescriptors: [NSSortDescriptor]? = nil,
        limit: Int? = nil
    ) async throws -> [T] {
        var results: [T] = []
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        let (matched, _) = try await database(for: scope).records(matching: query, inZoneWith: nil, resultsLimit: limit ?? CKQueryOperation.maximumResults)
        for value in matched.values {
            switch value {
            case .success(let record):
                results.append(try T(record: record))
            case .failure(let error):
                throw CloudKitError.operationFailed(error.localizedDescription)
            }
        }
        return results
    }

    private func record<T: CloudKitRecordConvertible>(for id: CKRecord.ID, scope: CKDatabase.Scope) async throws -> T? {
        do {
            let record = try await database(for: scope).record(for: id)
            return try T(record: record)
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil
            }
            throw CloudKitError.operationFailed(error.localizedDescription)
        }
    }

    // MARK: - User Profile

    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        try await record(for: CKRecord.ID(recordName: userId), scope: .private)
    }

    func upsertUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        try await save(profile, scope: .private)
    }

    // MARK: - Brands

    func fetchBrands(userId: String) async throws -> [Brand] {
        let predicate = NSPredicate(format: "userId == %@", userId)
        return try await fetch(recordType: Brand.recordType, predicate: predicate, scope: .private)
    }

    func saveBrand(_ brand: Brand) async throws -> Brand {
        try await save(brand, scope: .private)
    }

    // MARK: - Campaign Plans

    func fetchCampaignPlans(userId: String, brandId: String? = nil) async throws -> [CampaignPlan] {
        let predicate: NSPredicate
        if let brandId {
            predicate = NSPredicate(format: "userId == %@ AND brandId == %@", userId, brandId)
        } else {
            predicate = NSPredicate(format: "userId == %@", userId)
        }
        let sort = NSSortDescriptor(key: "createdAt", ascending: false)
        return try await fetch(recordType: CampaignPlan.recordType, predicate: predicate, scope: .private, sortDescriptors: [sort])
    }

    func saveCampaignPlan(_ plan: CampaignPlan) async throws -> CampaignPlan {
        try await save(plan, scope: .private)
    }

    // MARK: - Calendar Items

    func fetchCalendarItems(userId: String, brandId: String? = nil) async throws -> [ContentCalendarItem] {
        let predicate: NSPredicate
        if let brandId {
            predicate = NSPredicate(format: "userId == %@ AND brandId == %@", userId, brandId)
        } else {
            predicate = NSPredicate(format: "userId == %@", userId)
        }
        let sort = NSSortDescriptor(key: "date", ascending: true)
        return try await fetch(recordType: ContentCalendarItem.recordType, predicate: predicate, scope: .private, sortDescriptors: [sort])
    }

    func saveCalendarItem(_ item: ContentCalendarItem) async throws -> ContentCalendarItem {
        try await save(item, scope: .private)
    }

    // MARK: - Templates

    func fetchTemplates() async throws -> [TemplateItem] {
        try await fetch(recordType: TemplateItem.recordType, scope: .public)
    }

    func saveTemplate(_ template: TemplateItem) async throws -> TemplateItem {
        try await save(template, scope: .public)
    }

    // MARK: - Affiliate Tools

    func fetchAffiliateTools() async throws -> [AffiliateTool] {
        try await fetch(recordType: AffiliateTool.recordType, scope: .public)
    }

    func saveAffiliateTool(_ tool: AffiliateTool) async throws -> AffiliateTool {
        try await save(tool, scope: .public)
    }

    func logAffiliateClick(_ click: AffiliateClick) async throws {
        _ = try await save(click, scope: .private)
    }

    // MARK: - Bookings

    func saveBooking(_ booking: Booking) async throws -> Booking {
        try await save(booking, scope: .private)
    }
}
