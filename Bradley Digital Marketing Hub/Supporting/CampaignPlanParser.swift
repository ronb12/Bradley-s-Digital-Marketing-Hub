import Foundation

enum CampaignPlanParser {
    static func hookIdeas(from outline: String) -> [String] {
        var inHooks = false
        var hooks: [String] = []

        for line in outline.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("HOOK IDEAS") {
                inHooks = true
                continue
            }
            guard inHooks else { continue }

            if trimmed.hasPrefix("CONTENT THEMES") || trimmed.hasPrefix("CALL-TO-ACTION") || trimmed.hasPrefix("EXECUTION") {
                break
            }

            if trimmed.hasPrefix("•") {
                let idea = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                if !idea.isEmpty { hooks.append(idea) }
            }
        }

        return hooks
    }
}
