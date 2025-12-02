import Foundation

@MainActor
final class CampaignPlannerViewModel: ObservableObject {
    @Published var platform: MarketingPlatform = .instagram
    @Published var budget: Double = 500
    @Published var goalOption: CampaignGoalOption = .predefined(.awareness)
    @Published var customGoal: String = ""
    @Published var selectedBrand: Brand?
    @Published var outline: String = ""
    @Published var statusMessage: String?
    @Published var isSaving = false

    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }
    
    var goalText: String {
        switch goalOption {
        case .predefined(let goal):
            return goal.rawValue
        case .custom:
            return customGoal.isEmpty ? "Awareness" : customGoal
        }
    }

    func generateOutline() {
        outline = generateRealCampaignOutline()
    }
    
    private func generateRealCampaignOutline() -> String {
        let goal = goalText
        let duration = budget < 1000 ? 7 : budget < 3000 ? 14 : 30
        let adBudget = Int(budget * 0.4)
        let creatorBudget = Int(budget * 0.3)
        let toolsBudget = Int(budget * 0.3)
        
        let hooks = getHookIdeas(platform: platform, goal: goal)
        let themes = getContentThemes(platform: platform, goal: goal)
        let ctas = getCTASuggestions(platform: platform, goal: goal)
        let strategy = getStrategy(platform: platform, goal: goal)
        
        return """
        CAMPAIGN OVERVIEW
        Platform: \(platform.rawValue)
        Goal: \(goal)
        Duration: \(duration) days
        Total Budget: $\(Int(budget))
        
        BUDGET BREAKDOWN
        • Paid Advertising: $\(adBudget)
        • Creator Partnerships: $\(creatorBudget)
        • Tools & Software: $\(toolsBudget)
        
        HOOK IDEAS
        \(hooks.map { "• \($0)" }.joined(separator: "\n        "))
        
        CONTENT THEMES
        \(themes.map { "• \($0)" }.joined(separator: "\n        "))
        
        CALL-TO-ACTION STRATEGY
        \(ctas.map { "• \($0)" }.joined(separator: "\n        "))
        
        EXECUTION STRATEGY
        \(strategy)
        
        KEY METRICS TO TRACK
        • Engagement rate
        • Click-through rate
        • Conversion rate
        • Cost per acquisition
        """
    }
    
    private func getHookIdeas(platform: MarketingPlatform, goal: String) -> [String] {
        let goalLower = goal.lowercased()
        
        switch platform {
        case .instagram:
            if goalLower.contains("awareness") {
                return [
                    "Behind-the-scenes Reel showing your process",
                    "Day-in-the-life Story highlight series",
                    "Before/after transformation visual carousel",
                    "Quick tip video using trending audio",
                    "Customer testimonial quote graphics"
                ]
            } else if goalLower.contains("lead") || goalLower.contains("conversion") {
                return [
                    "Problem/solution carousel post",
                    "Limited-time offer announcement",
                    "Free resource preview with opt-in",
                    "Success story case study",
                    "FAQ addressing common objections"
                ]
            } else {
                return [
                    "Product/service demo Reel",
                    "User-generated content compilation",
                    "Expert tips carousel",
                    "Trending challenge participation",
                    "Community spotlight feature"
                ]
            }
            
        case .tiktok:
            return [
                "POV: You're struggling with [problem]",
                "3 things I wish I knew before...",
                "Day in the life of a [role]",
                "Things they don't tell you about...",
                "If you [action], try this instead"
            ]
            
        case .facebook:
            return [
                "Share a personal story or journey",
                "Ask engaging questions to spark discussion",
                "Post valuable tips or how-to content",
                "Share behind-the-scenes content",
                "Create polls or interactive content"
            ]
            
        case .linkedin:
            if goalLower.contains("awareness") {
                return [
                    "Industry insight with data/statistics",
                    "Career journey story post",
                    "Thought leadership piece on trends",
                    "Lessons learned from failure/success",
                    "Industry prediction or forecast"
                ]
            } else {
                return [
                    "Problem-solving case study",
                    "ROI-focused success story",
                    "Professional tip or framework",
                    "Industry best practices guide",
                    "Solution-oriented carousel post"
                ]
            }
            
        case .youtube:
            return [
                "How-to tutorial addressing specific problem",
                "Case study with real results",
                "Expert interview or panel discussion",
                "Tool/strategy review and comparison",
                "Step-by-step guide series"
            ]
            
        case .pinterest:
            return [
                "Step-by-step infographic guide",
                "Before/after visual comparison",
                "Quick tip graphic card",
                "Checklist or resource list",
                "Inspirational quote with actionable tip"
            ]
            
        case .email:
            return [
                "Personalized story opening",
                "Problem statement that resonates",
                "Exclusive offer or early access",
                "Value-packed subject line",
                "Curiosity-driven preview text"
            ]
        }
    }
    
    private func getContentThemes(platform: MarketingPlatform, goal: String) -> [String] {
        let goalLower = goal.lowercased()
        
        switch platform {
        case .instagram:
            return [
                "Monday Motivation - Inspirational quotes and tips",
                "Wednesday Wisdom - Educational content and insights",
                "Friday Feature - Showcase customer success stories",
                "Story Highlights - Behind-the-scenes daily content",
                "Weekend Wins - Celebrate community achievements"
            ]
            
        case .tiktok:
            return [
                "Monday Micro-Lesson - Quick 15-second tips",
                "Trending Tuesdays - Join trending sounds/challenges",
                "Wednesday Wisdom - Educational content",
                "Throwback Thursday - Share journey highlights",
                "Feature Friday - Customer/community spotlights"
            ]
            
        case .facebook:
            return [
                "Community engagement posts",
                "Value-driven educational content",
                "Behind-the-scenes business updates",
                "Customer testimonials and reviews",
                "Interactive polls and discussions"
            ]
            
        case .linkedin:
            if goalLower.contains("awareness") {
                return [
                    "Industry insights and analysis",
                    "Thought leadership articles",
                    "Professional development tips",
                    "Networking and relationship building",
                    "Trend discussions and predictions"
                ]
            } else {
                return [
                    "Solution-focused case studies",
                    "ROI and results-oriented content",
                    "Problem-solving frameworks",
                    "Client success stories",
                    "Conversion-focused strategies"
                ]
            }
            
        case .youtube:
            return [
                "Educational tutorials and guides",
                "Case studies with real data",
                "Expert interviews and panels",
                "Tool reviews and comparisons",
                "Strategy deep-dives"
            ]
            
        case .pinterest:
            return [
                "How-to guides and tutorials",
                "Inspirational and motivational content",
                "Resource lists and checklists",
                "Visual tips and quick wins",
                "Planning and organization content"
            ]
            
        case .email:
            return [
                "Weekly newsletter with insights",
                "Product/service announcements",
                "Educational series",
                "Exclusive offers and promotions",
                "Customer success stories"
            ]
        }
    }
    
    private func getCTASuggestions(platform: MarketingPlatform, goal: String) -> [String] {
        let goalLower = goal.lowercased()
        
        if goalLower.contains("awareness") {
            return [
                "Follow for more tips",
                "Save this post for later",
                "Share with someone who needs this",
                "Comment your thoughts below",
                "Turn on post notifications"
            ]
        } else if goalLower.contains("lead") || goalLower.contains("conversion") {
            return [
                "Book a free consultation",
                "Download our free guide",
                "Start your free trial",
                "Schedule a discovery call",
                "Join our waitlist"
            ]
        } else {
            return [
                "Learn more on our website",
                "Sign up for our newsletter",
                "Follow for daily tips",
                "Download the free resource",
                "Book a strategy call"
            ]
        }
    }
    
    private func getStrategy(platform: MarketingPlatform, goal: String) -> String {
        let goalLower = goal.lowercased()
        let duration = budget < 1000 ? 7 : budget < 3000 ? 14 : 30
        
        switch platform {
        case .instagram:
            if goalLower.contains("awareness") {
                return """
                Post daily content for \(duration) days with:
                - 3-4 feed posts per week
                - Daily Stories with engagement stickers
                - 2-3 Reels per week using trending audio
                - Engage with comments within 1 hour
                - Use 15-20 relevant hashtags per post
                """
            } else {
                return """
                Focus on conversion-optimized content:
                - Carousel posts showcasing benefits
                - Reels directing to link in bio
                - Stories with swipe-up CTA
                - Strategic retargeting ads
                - Email capture via lead magnets
                """
            }
            
        case .tiktok:
            return """
            Post 3-5 videos per week:
            - Jump on trending sounds early
            - Use popular hashtags in niche
            - Engage in comments immediately
            - Cross-promote to other platforms
            - Focus on authentic, behind-the-scenes content
            """
            
        case .facebook:
            return """
            Daily community engagement:
            - Post 3-5 times per week
            - Respond to all comments
            - Create Facebook Groups for community
            - Use Facebook Events for webinars/launches
            - Leverage Facebook Ads for targeting
            """
            
        case .linkedin:
            return """
            Professional content strategy:
            - Post 3-4 times per week
            - Engage in relevant industry discussions
            - Share thought leadership articles
            - Connect with target audience daily
            - Use LinkedIn Ads for precise targeting
            """
            
        case .youtube:
            return """
            Consistent video publishing:
            - 2-3 videos per week
            - Optimize titles and descriptions
            - Create engaging thumbnails
            - Engage with comments
            - Use YouTube Shorts for discovery
            """
            
        case .pinterest:
            return """
            Pinterest SEO strategy:
            - Pin 5-10 times per day
            - Use keyword-rich descriptions
            - Create multiple pins per blog post
            - Join relevant group boards
            - Schedule pins at peak times
            """
            
        case .email:
            return """
            Email marketing cadence:
            - Send 2-3 emails per week
            - Segment your list by interest
            - A/B test subject lines
            - Personalize content
            - Track open and click rates
            """
        }
    }

    func savePlan(userId: String, brandId: String?, currentCount: Int, tier: SubscriptionTier) async {
        if let limit = tier.maxCampaignPlans, currentCount >= limit {
            statusMessage = "Upgrade to unlock more campaign plans."
            return
        }
        guard !outline.isEmpty else {
            statusMessage = "Generate a plan before saving."
            return
        }
        isSaving = true
        defer { isSaving = false }
        let plan = CampaignPlan(
            userId: userId,
            brandId: brandId,
            platform: platform.rawValue,
            budget: budget,
            goal: goalText,
            outlineDetails: outline
        )
        do {
            _ = try await service.saveCampaignPlan(plan)
            statusMessage = "Campaign saved to CloudKit."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
