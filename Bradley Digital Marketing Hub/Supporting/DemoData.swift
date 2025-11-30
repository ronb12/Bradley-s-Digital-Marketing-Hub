import Foundation

enum DemoData {
    static func brands(userId: String) -> [Brand] {
        [
            Brand(
                id: "demo-brand-social-labs",
                userId: userId,
                name: "Social Labs Co.",
                industry: "Education",
                colorHex: "#5B8DEF"
            ),
            Brand(
                id: "demo-brand-growth-studio",
                userId: userId,
                name: "Growth Studio Agency",
                industry: "Professional Services",
                colorHex: "#2AA876"
            )
        ]
    }

    static func campaignPlans(userId: String, brandId: String?) -> [CampaignPlan] {
        [
            CampaignPlan(
                id: "demo-campaign-spring",
                userId: userId,
                brandId: brandId,
                platform: "Instagram",
                budget: 2500,
                goal: "Awareness",
                outlineDetails: """
                Hook Ideas: Behind-the-scenes Reel series featuring a 14-day sprint.
                Content Themes: Founder spotlight, community wins, weekly giveaways.
                CTA: Book a discovery call, download the free playbook.
                Duration: 2-week burst with daily Stories support.
                """,
                createdAt: Date().addingTimeInterval(-86400 * 2)
            ),
            CampaignPlan(
                id: "demo-campaign-leads",
                userId: userId,
                brandId: brandId,
                platform: "LinkedIn",
                budget: 1800,
                goal: "Leads",
                outlineDetails: """
                Hook Ideas: \"Predictable pipeline\" carousel.
                Content Themes: Playbook snippets, client testimonials, live Q&A teaser.
                CTA: Secure a funnel audit.
                Duration: 10 days with retargeting on day 7.
                """,
                createdAt: Date().addingTimeInterval(-86400 * 5)
            )
        ]
    }

    static func calendarItems(userId: String, brandId: String?) -> [ContentCalendarItem] {
        [
            ContentCalendarItem(
                id: "demo-calendar-launch",
                userId: userId,
                brandId: brandId,
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                platform: "Instagram",
                title: "Launch teaser Reel",
                notes: "Share B-roll montage with trending audio."
            ),
            ContentCalendarItem(
                id: "demo-calendar-live",
                userId: userId,
                brandId: brandId,
                date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                platform: "LinkedIn",
                title: "Live AMA announcement",
                notes: "Tag partners, include event link."
            )
        ]
    }

    static var templates: [TemplateItem] {
        [
            TemplateItem(
                id: "demo-template-campaign-brief",
                name: "Campaign Brief Template",
                description: "Structured outline to communicate goals, budget, and KPIs.",
                isPremium: false,
                isAgencyOnly: false
            ),
            TemplateItem(
                id: "demo-template-agency-proposal",
                name: "Agency Proposal Deck",
                description: "Pitch deck with pricing tiers and service scope.",
                isPremium: true,
                isAgencyOnly: false
            ),
            TemplateItem(
                id: "demo-template-fractional-cmo",
                name: "Fractional CMO Gameplan",
                description: "Agency-only roadmap for onboarding new retainers.",
                isPremium: true,
                isAgencyOnly: true
            )
        ]
    }

    static var affiliateTools: [AffiliateTool] {
        [
            AffiliateTool(
                id: "demo-affiliate-scheduler",
                name: "ScheduleFlow",
                shortDescription: "Cross-platform content scheduler with AI topic surfacing.",
                url: "https://example.com/scheduleflow",
                isProRecommended: true
            ),
            AffiliateTool(
                id: "demo-affiliate-analytics",
                name: "PulseMetrics",
                shortDescription: "Lightweight analytics dashboard for marketing teams.",
                url: "https://example.com/pulsemetrics",
                isProRecommended: false
            )
        ]
    }
}
