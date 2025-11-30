import Foundation

struct DemoSeedResult {
    let brandCount: Int
    let campaignCount: Int
    let calendarCount: Int
    let templateCount: Int
    let affiliateToolCount: Int

    var summary: String {
        "Seeded \(brandCount) brands, \(campaignCount) campaigns, \(calendarCount) calendar items, \(templateCount) templates, \(affiliateToolCount) affiliate tools."
    }
}

final class DemoDataSeeder {
    private let cloudKitService: CloudKitService

    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }

    func seed(for userId: String) async throws -> DemoSeedResult {
        let savedBrands = try await seedBrands(userId: userId)
        let brandId = savedBrands.first?.id
        let campaigns = try await seedCampaignPlans(userId: userId, brandId: brandId)
        let calendarItems = try await seedCalendarItems(userId: userId, brandId: brandId)
        let templates = try await seedTemplates()
        let affiliateTools = try await seedAffiliateTools()

        return DemoSeedResult(
            brandCount: savedBrands.count,
            campaignCount: campaigns,
            calendarCount: calendarItems,
            templateCount: templates,
            affiliateToolCount: affiliateTools
        )
    }

    private func seedBrands(userId: String) async throws -> [Brand] {
        var results: [Brand] = []
        for brand in DemoData.brands(userId: userId) {
            let saved = try await cloudKitService.saveBrand(brand)
            results.append(saved)
        }
        return results
    }

    private func seedCampaignPlans(userId: String, brandId: String?) async throws -> Int {
        var count = 0
        for plan in DemoData.campaignPlans(userId: userId, brandId: brandId) {
            _ = try await cloudKitService.saveCampaignPlan(plan)
            count += 1
        }
        return count
    }

    private func seedCalendarItems(userId: String, brandId: String?) async throws -> Int {
        var count = 0
        for item in DemoData.calendarItems(userId: userId, brandId: brandId) {
            _ = try await cloudKitService.saveCalendarItem(item)
            count += 1
        }
        return count
    }

    private func seedTemplates() async throws -> Int {
        var count = 0
        for template in DemoData.templates {
            await cloudKitService.deleteTemplate(withID: template.id)
            _ = try await cloudKitService.saveTemplate(template)
            count += 1
        }
        return count
    }

    private func seedAffiliateTools() async throws -> Int {
        var count = 0
        for tool in DemoData.affiliateTools {
            await cloudKitService.deleteAffiliateTool(withID: tool.id)
            _ = try await cloudKitService.saveAffiliateTool(tool)
            count += 1
        }
        return count
    }
}
