import Foundation
import SwiftUI

@MainActor
final class ContentGeneratorViewModel: ObservableObject {
    @Published var businessTypeOption: BusinessTypeOption = .predefined(.other)
    @Published var customBusinessType: String = ""
    @Published var audienceOption: TargetAudienceOption = .predefined(.other)
    @Published var customAudience: String = ""
    @Published var tone: MarketingTone = .friendly
    @Published var platform: MarketingPlatform = .instagram
    @Published var generatedContent: [GeneratedContentItem] = []
    @Published var isSaving = false
    @Published var statusMessage: String?
    @Published var copyStatusMessage: String?

    private let service: CloudKitService
    
    struct GeneratedContentItem: Identifiable {
        let id = UUID()
        var content: String
        var platform: MarketingPlatform
        
        init(content: String, platform: MarketingPlatform) {
            self.content = content
            self.platform = platform
        }
    }

    init(service: CloudKitService) {
        self.service = service
    }
    
    var businessTypeText: String {
        switch businessTypeOption {
        case .predefined(let type):
            return type.rawValue
        case .custom:
            return customBusinessType.isEmpty ? "any business" : customBusinessType
        }
    }
    
    var audienceText: String {
        switch audienceOption {
        case .predefined(let audience):
            return audience.rawValue
        case .custom:
            return customAudience.isEmpty ? "their audience" : customAudience
        }
    }

    func generate() {
        let contentPieces = generatePlatformSpecificContent()
        generatedContent = contentPieces.map { GeneratedContentItem(content: $0, platform: platform) }
    }
    
    func regenerateItem(at index: Int) {
        guard index < generatedContent.count else { return }
        let newContent = generateSinglePiece()
        generatedContent[index].content = newContent
    }
    
    func updateContent(at id: UUID, to newContent: String) {
        if let index = generatedContent.firstIndex(where: { $0.id == id }) {
            generatedContent[index].content = newContent
        }
    }
    
    private func generateSinglePiece() -> String {
        let business = businessTypeText
        let targetAudience = audienceText
        let selectedTone = tone
        
        switch platform {
        case .instagram:
            let pieces = generateInstagramContent(business: business, audience: targetAudience, tone: selectedTone)
            return pieces.randomElement() ?? pieces[0]
        case .tiktok:
            let pieces = generateTikTokContent(business: business, audience: targetAudience, tone: selectedTone)
            return pieces.randomElement() ?? pieces[0]
        case .facebook:
            let pieces = generateFacebookContent(business: business, audience: targetAudience, tone: selectedTone)
            return pieces.randomElement() ?? pieces[0]
        case .linkedin:
            let pieces = generateLinkedInContent(business: business, audience: targetAudience, tone: selectedTone)
            return pieces.randomElement() ?? pieces[0]
        case .youtube:
            let pieces = generateYouTubeContent(business: business, audience: targetAudience, tone: selectedTone)
            return pieces.randomElement() ?? pieces[0]
        case .pinterest:
            let pieces = generatePinterestContent(business: business, audience: targetAudience, tone: selectedTone)
            return pieces.randomElement() ?? pieces[0]
        case .email:
            let pieces = generateEmailContent(business: business, audience: targetAudience, tone: selectedTone)
            return pieces.randomElement() ?? pieces[0]
        }
    }
    
    func saveAsFavorite(content: String, userId: String, platform: MarketingPlatform) async {
        // Save to UserDefaults for now, can be enhanced with CloudKit later
        var favorites = UserDefaults.standard.array(forKey: "savedContentFavorites") as? [[String: String]] ?? []
        let favorite: [String: String] = [
            "content": content,
            "platform": platform.rawValue,
            "date": ISO8601DateFormatter().string(from: Date()),
            "id": UUID().uuidString
        ]
        favorites.append(favorite)
        UserDefaults.standard.set(favorites, forKey: "savedContentFavorites")
        await MainActor.run {
            statusMessage = "Saved to favorites!"
        }
    }
    
    private func generatePlatformSpecificContent() -> [String] {
        let business = businessTypeText
        let targetAudience = audienceText
        let selectedTone = tone
        
        switch platform {
        case .instagram:
            return generateInstagramContent(business: business, audience: targetAudience, tone: selectedTone)
        case .tiktok:
            return generateTikTokContent(business: business, audience: targetAudience, tone: selectedTone)
        case .facebook:
            return generateFacebookContent(business: business, audience: targetAudience, tone: selectedTone)
        case .linkedin:
            return generateLinkedInContent(business: business, audience: targetAudience, tone: selectedTone)
        case .youtube:
            return generateYouTubeContent(business: business, audience: targetAudience, tone: selectedTone)
        case .pinterest:
            return generatePinterestContent(business: business, audience: targetAudience, tone: selectedTone)
        case .email:
            return generateEmailContent(business: business, audience: targetAudience, tone: selectedTone)
        }
    }
    
    private func generateInstagramContent(business: String, audience: String, tone: MarketingTone) -> [String] {
        let emoji = tone == .friendly ? "✨" : tone == .motivational ? "💪" : tone == .luxury ? "🌟" : "📈"
        let hashtags = generateHashtags(business: business)
        
        let content1 = getInstagramContent1(business: business, audience: audience, tone: tone, emoji: emoji)
        let content2 = getInstagramContent2(business: business, audience: audience, tone: tone)
        let content3 = getInstagramContent3(business: business, audience: audience, tone: tone)
        
        return [
            "\(content1)\n\n\(hashtags)",
            "\(content2)\n\n\(hashtags)",
            "\(content3)\n\n\(hashtags)"
        ]
    }
    
    private func getInstagramContent1(business: String, audience: String, tone: MarketingTone, emoji: String) -> String {
        let tips = getBusinessSpecificTips(business: business)
        let tip = tips.randomElement() ?? "consistency is key to building a strong brand"
        
        switch tone {
        case .friendly:
            return """
            \(emoji) Hey \(audience)! Quick question for you:
            
            What's one thing you wish you knew when you first started?
            
            For us, it was realizing that \(tip). This completely changed how we approach our \(business).
            
            Drop your answer below - we'd love to hear from you! 👇
            
            And if this resonates, save this post for later! 💫
            """
        case .motivational:
            return """
            \(emoji) Monday motivation for all the \(audience) out there!
            
            Remember: \(tip.capitalized). 
            
            Building a successful \(business) doesn't happen overnight. It's about showing up every single day, even when it's hard.
            
            You've got this! 💪
            
            What's motivating you this week? Share below!
            """
        case .luxury:
            return """
            \(emoji) Excellence is in the details.
            
            For our \(audience), we believe \(tip). This philosophy guides everything we do at our \(business).
            
            Quality over quantity. Always.
            
            What does excellence mean to you?
            """
        case .professional:
            return """
            📊 Quick insight for \(audience):
            
            Data shows that \(tip) can significantly impact your \(business) growth.
            
            We've seen this strategy work time and time again with our clients.
            
            Want to learn more? Let's connect in the comments.
            """
        }
    }
    
    private func getInstagramContent2(business: String, audience: String, tone: MarketingTone) -> String {
        let tip = getBusinessSpecificTips(business: business).randomElement() ?? "building trust takes time"
        
        switch tone {
        case .friendly:
            return """
            📸 Real talk time!
            
            Running a \(business) comes with its challenges. But here's something we learned that might help you too:
            
            \(tip.capitalized).
            
            It sounds simple, but this one mindset shift made all the difference for us.
            
            Who else can relate? 🙋‍♀️
            
            Save this if you needed this reminder today! ✨
            """
        case .motivational:
            return """
            💥 Stop waiting for the "perfect" moment.
            
            Your \(audience) needs what you have to offer NOW. Not next month. Not when everything is "ready."
            
            \(tip.capitalized). Start where you are, use what you have.
            
            What are you waiting for? Let's go! 🚀
            """
        case .luxury:
            return """
            🌟 Craftsmanship. Elegance. Timeless value.
            
            In a world of fast everything, we choose to build our \(business) differently.
            
            \(tip.capitalized). This is what sets us apart.
            
            Join us in celebrating true quality.
            """
        case .professional:
            return """
            📈 Three strategies that transformed our \(business):
            
            1. \(tip.capitalized)
            2. Building authentic relationships with \(audience)
            3. Consistent value delivery
            
            Which of these resonates most with you?
            
            Let's discuss in the comments below.
            """
        }
    }
    
    private func getInstagramContent3(business: String, audience: String, tone: MarketingTone) -> String {
        let steps = getBusinessSpecificSteps(business: business)
        
        switch tone {
        case .friendly:
            return """
            🎯 Quick win for your \(business)!
            
            Here's a simple 3-step process you can try TODAY:
            
            1️⃣ \(steps[0])
            2️⃣ \(steps[1])
            3️⃣ \(steps[2])
            
            It takes just 15 minutes, but the impact? Huge! 
            
            Give it a try and let us know how it goes! We're cheering you on! 🔥
            """
        case .motivational:
            return """
            💪 Your action plan for this week:
            
            ✅ \(steps[0])
            ✅ \(steps[1])
            ✅ \(steps[2])
            
            These three actions can move the needle for your \(business).
            
            Print this. Screenshot this. Make it happen!
            
            What's one thing you'll commit to today? 💯
            """
        case .luxury:
            return """
            ✨ The refined approach to \(business) success:
            
            • \(steps[0])
            • \(steps[1])
            • \(steps[2])
            
            Excellence is a choice. Choose it daily.
            
            Which principle guides your business?
            """
        case .professional:
            return """
            📊 Three data-driven strategies for \(business) growth:
            
            1. \(steps[0])
            2. \(steps[1])
            3. \(steps[2])
            
            Implement these systematically and track your results.
            
            Ready to scale? Let's connect.
            """
        }
    }
    
    private func getBusinessSpecificTips(business: String) -> [String] {
        let lowerBusiness = business.lowercased()
        
        if lowerBusiness.contains("e-commerce") || lowerBusiness.contains("online") {
            return [
                "customer reviews are your secret weapon",
                "fast shipping beats perfect packaging every time",
                "your email list is worth more than social media followers",
                "return customers spend 67% more than new ones",
                "product photos can make or break a sale"
            ]
        } else if lowerBusiness.contains("saas") || lowerBusiness.contains("tech") || lowerBusiness.contains("software") {
            return [
                "your onboarding process determines customer retention",
                "feature requests are goldmines for product development",
                "documentation is as important as the product itself",
                "free trials convert better than demos",
                "customer success drives renewals"
            ]
        } else if lowerBusiness.contains("fitness") || lowerBusiness.contains("wellness") || lowerBusiness.contains("health") {
            return [
                "consistency beats intensity every single time",
                "community support is the #1 predictor of success",
                "small daily habits create massive transformations",
                "progress photos matter more than the scale",
                "rest days are training days too"
            ]
        } else if lowerBusiness.contains("coach") || lowerBusiness.contains("consult") {
            return [
                "your expertise is valuable, charge accordingly",
                "case studies are your best sales tool",
                "group programs scale better than 1-on-1",
                "clear frameworks sell better than vague promises",
                "client results are your marketing"
            ]
        } else if lowerBusiness.contains("food") || lowerBusiness.contains("restaurant") || lowerBusiness.contains("beverage") {
            return [
                "fresh ingredients speak louder than fancy marketing",
                "local community support is everything",
                "Instagram-worthy presentation drives sales",
                "consistency in quality builds reputation",
                "seasonal menu updates keep customers coming back"
            ]
        } else if lowerBusiness.contains("fashion") || lowerBusiness.contains("beauty") {
            return [
                "authentic style resonates more than trends",
                "sustainability sells to conscious consumers",
                "size inclusivity is not optional",
                "user-generated content builds trust",
                "quality basics outperform trendy pieces"
            ]
        } else if lowerBusiness.contains("real estate") {
            return [
                "location will always be the top priority",
                "staging can increase sale price by 5-10%",
                "professional photography pays for itself",
                "local market knowledge builds trust",
                "virtual tours are now essential"
            ]
        } else if lowerBusiness.contains("finance") || lowerBusiness.contains("invest") {
            return [
                "compound interest is the 8th wonder of the world",
                "diversification reduces risk without reducing returns",
                "starting early beats timing the market",
                "financial education creates better clients",
                "transparency builds trust in finance"
            ]
        } else if lowerBusiness.contains("education") || lowerBusiness.contains("train") {
            return [
                "engagement beats perfection in teaching",
                "bite-sized lessons are more effective",
                "student success stories are your best marketing",
                "community learning drives completion rates",
                "practical application beats theory"
            ]
        } else if lowerBusiness.contains("agency") || lowerBusiness.contains("marketing") {
            return [
                "results speak louder than case studies",
                "client communication prevents 90% of problems",
                "specialization beats generalization",
                "transparent reporting builds long-term relationships",
                "your team is your competitive advantage"
            ]
        } else {
            return [
                "understanding your customer is everything",
                "consistency builds trust and recognition",
                "value first, sales second",
                "authentic storytelling connects with people",
                "small improvements compound over time"
            ]
        }
    }
    
    private func getBusinessSpecificSteps(business: String) -> [String] {
        let lowerBusiness = business.lowercased()
        
        if lowerBusiness.contains("e-commerce") || lowerBusiness.contains("online") {
            return [
                "Optimize your product titles with keywords your customers search",
                "Add customer reviews to your top 3 bestsellers",
                "Send a follow-up email 24 hours after purchase"
            ]
        } else if lowerBusiness.contains("saas") || lowerBusiness.contains("tech") {
            return [
                "Review your onboarding flow - is it clear and simple?",
                "Check your help center analytics - what are users searching?",
                "Send a \"how can we improve\" survey to active users"
            ]
        } else if lowerBusiness.contains("fitness") || lowerBusiness.contains("wellness") {
            return [
                "Plan your workouts for the week and schedule them",
                "Prepare healthy snacks in advance",
                "Find an accountability partner or join a community"
            ]
        } else if lowerBusiness.contains("coach") || lowerBusiness.contains("consult") {
            return [
                "Document one client success story from this month",
                "Create a free resource that solves a common problem",
                "Reach out to 3 past clients for testimonials"
            ]
        } else if lowerBusiness.contains("food") || lowerBusiness.contains("restaurant") {
            return [
                "Take 5 new photos of your best dishes",
                "Update your menu descriptions to be more appealing",
                "Ask 3 regular customers what they'd recommend to friends"
            ]
        } else if lowerBusiness.contains("fashion") || lowerBusiness.contains("beauty") {
            return [
                "Create a style guide for your target customer",
                "Feature customer photos in your next post",
                "Share the story behind your best-selling item"
            ]
        } else if lowerBusiness.contains("real estate") {
            return [
                "Update your listings with professional photos",
                "Research 3 new local market trends to share",
                "Connect with 2 local businesses for partnerships"
            ]
        } else if lowerBusiness.contains("finance") || lowerBusiness.contains("invest") {
            return [
                "Create a simple financial tip to share this week",
                "Review and simplify your service explanations",
                "Share one common mistake people make and how to avoid it"
            ]
        } else if lowerBusiness.contains("education") || lowerBusiness.contains("train") {
            return [
                "Break down one complex topic into 3 simple points",
                "Create a quick checklist for your students",
                "Ask for feedback from your most engaged learners"
            ]
        } else if lowerBusiness.contains("agency") || lowerBusiness.contains("marketing") {
            return [
                "Analyze your last campaign - what worked best?",
                "Create a case study from a recent client win",
                "Update your services page with specific outcomes"
            ]
        } else {
            return [
                "Identify your customer's biggest pain point",
                "Create content that solves that problem",
                "Share it in 3 places your audience hangs out"
            ]
        }
    }
    
    private func generateTikTokContent(business: String, audience: String, tone: MarketingTone) -> [String] {
        let tips = getBusinessSpecificTips(business: business)
        let tip = tips.randomElement() ?? "consistency is everything"
        let businessTag = business.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "/", with: "")
        
        return [
            """
            POV: You're a \(business) owner trying to reach your \(audience) 👀
            
            Here's what actually works:
            ⚡ \(tip.capitalized)
            💡 Show up consistently
            🔥 Add value first, sell second
            
            Try it for 30 days and tell me if it works!
            
            #\(businessTag) #MarketingTips #SmallBusiness #Entrepreneur #BusinessTips
            """,
            """
            Day in the life of a \(business) owner:
            
            ✨ Morning: Planning content and checking analytics
            📱 Afternoon: Creating and engaging with \(audience)
            🌙 Evening: Reviewing what worked, planning tomorrow
            
            It's not glamorous, but it's real. Who can relate? 🙋‍♀️
            
            #DayInTheLife #\(businessTag) #BusinessOwner #EntrepreneurLife #BehindTheScenes
            """,
            """
            STOP doing this if you want to grow your \(business) 🛑
            
            Waiting for perfect content to post.
            Posting only when you "feel inspired."
            Comparing your day 1 to someone's day 1000.
            
            Instead: Post consistently. Show your process. Focus on YOUR journey.
            
            This mindset shift changed everything for us! 💯
            
            #BusinessTips #\(businessTag) #Growth #Mindset #SmallBusinessTips
            """
        ]
    }
    
    private func generateFacebookContent(business: String, audience: String, tone: MarketingTone) -> [String] {
        let tips = getBusinessSpecificTips(business: business)
        let tip = tips.randomElement() ?? "building relationships takes time"
        
        return [
            """
            Hey \(audience)! 👋
            
            We wanted to share something important with our community today.
            
            As a \(business), we understand the challenges you face. That's why we want to share this:
            
            \(tip.capitalized). This simple truth has made a huge difference in how we connect with our community.
            
            💬 We'd love to hear your thoughts! What's one lesson that changed how you approach your business?
            
            Tag a friend who needs to see this!
            """,
            """
            Community spotlight! 🌟
            
            We're so grateful for our \(audience) and the amazing community we've built together.
            
            This week, we want to celebrate:
            • The authentic conversations happening in our group
            • The wins you're sharing with us
            • The support you're showing each other
            
            What brings you to our community? What keeps you coming back?
            
            Share your story in the comments below - we'd love to hear it!
            """,
            """
            Quick poll for our \(audience): 
            
            What's your biggest challenge right now when it comes to growing your \(business)?
            
            A) Finding the right customers
            B) Creating consistent content
            C) Time management
            D) Pricing and profitability
            E) Something else (tell us below!)
            
            Your input helps us create content and resources that actually serve you! 🙏
            
            Drop your answer below - let's help each other!
            """
        ]
    }
    
    private func generateLinkedInContent(business: String, audience: String, tone: MarketingTone) -> [String] {
        let tips = getBusinessSpecificTips(business: business)
        let tip1 = tips.randomElement() ?? "authenticity builds trust"
        var remainingTips = tips.filter { $0 != tip1 }
        let tip2 = remainingTips.randomElement() ?? "consistency compounds over time"
        remainingTips = remainingTips.filter { $0 != tip2 }
        let tip3 = remainingTips.randomElement() ?? "customer focus drives growth"
        let businessTag = business.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "/", with: "")
        
        return [
            """
            Three lessons I learned building a \(business) that transformed how we reach our \(audience):
            
            1. \(tip1.capitalized)
            
            When we stopped trying to be everything to everyone and focused on being authentic, everything changed. Our \(audience) responded to real, genuine connection.
            
            2. \(tip2.capitalized)
            
            We committed to showing up consistently - not perfectly. Small daily actions created momentum that compounds over time.
            
            3. \(tip3.capitalized)
            
            Every decision now starts with: "Does this serve our \(audience)?" This focus has been the foundation of our growth.
            
            What's been your biggest learning in building your business? Share your thoughts in the comments.
            
            #BusinessStrategy #ProfessionalDevelopment #\(businessTag) #Entrepreneurship #BusinessGrowth
            """,
            """
            Quick thought on \(business) and \(audience) engagement:
            
            After analyzing thousands of interactions with our \(audience), one pattern stands out:
            
            The most successful content doesn't sell. It educates. It inspires. It creates connection.
            
            People buy from businesses they trust. And trust is built through consistent value delivery, not constant promotion.
            
            How are you prioritizing value over sales in your strategy?
            
            Would love to hear from fellow professionals in the comments.
            
            #IndustryInsights #BusinessGrowth #Networking #MarketingStrategy #ContentMarketing
            """,
            """
            How we're helping \(audience) succeed:
            
            After years in \(business), we've identified three critical factors that separate successful businesses from struggling ones:
            
            ✅ \(tip1.capitalized)
            
            This isn't just nice-to-have - it's essential. When you understand this, everything else falls into place.
            
            ✅ \(tip2.capitalized)
            
            Success isn't about one big breakthrough. It's about showing up consistently, even when it's hard.
            
            ✅ \(tip3.capitalized)
            
            Your customers should be at the center of every decision. When you serve them well, growth follows naturally.
            
            What would you add to this list based on your experience?
            
            #ProfessionalGrowth #BusinessDevelopment #\(businessTag) #BusinessStrategy #Entrepreneurship
            """
        ]
    }
    
    private func generateYouTubeContent(business: String, audience: String, tone: MarketingTone) -> [String] {
        let tips = getBusinessSpecificTips(business: business)
        let tip = tips.randomElement() ?? "consistency drives success"
        let businessTag = business.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "/", with: "")
        
        return [
            """
            🎬 Video Title: "How to Grow Your \(business) in 2024 | Complete Guide for \(audience)"
            
            Description:
            
            In this video, we're breaking down exactly how to grow your \(business) and reach more \(audience). Perfect for business owners looking to scale.
            
            📌 Timestamps:
            0:00 - Introduction
            2:15 - Understanding your \(audience)
            5:30 - \(tip.capitalized)
            8:45 - Building systems for consistency
            12:00 - Conclusion & Next Steps
            
            💡 Key takeaways:
            • Focus on one platform and master it first
            • \(tip.capitalized)
            • Build systems that work when you're not working
            
            Subscribe for more \(business) tips!
            
            #\(businessTag) #BusinessTips #SmallBusiness #Entrepreneur
            """,
            """
            🎥 Video Title: "The \(business) Strategy That 10X'd Our Results"
            
            Description:
            
            Today, we're sharing the exact strategy we used to grow our \(business) and better serve our \(audience).
            
            This simple framework works especially well for \(audience) and can be implemented starting today.
            
            🔗 Free Resource: Download our \(business) checklist in the description below!
            
            Like this video if you found it helpful!
            
            What topic should we cover next? Comment below!
            """,
            """
            📹 Video Title: "5 Mistakes \(business) Owners Make (And How to Avoid Them)"
            
            Description:
            
            After working with hundreds of \(audience), we've seen these mistakes over and over. Here's how to avoid them:
            
            Mistake #1: Trying to be perfect instead of consistent
            Mistake #2: Not understanding your \(audience)'s real needs
            Mistake #3: \(tip.capitalized)
            Mistake #4: Focusing on tactics instead of strategy
            Mistake #5: Going it alone instead of building a community
            
            Watch to learn how to avoid these common pitfalls!
            
            Which mistake have you made? Share in the comments!
            """
        ]
    }
    
    private func generatePinterestContent(business: String, audience: String, tone: MarketingTone) -> [String] {
        let tips = getBusinessSpecificTips(business: business)
        let tip = tips.randomElement() ?? "consistency builds trust"
        let steps = getBusinessSpecificSteps(business: business)
        let businessTag = business.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "/", with: "")
        
        return [
            """
            Pin Title: "\(business) Success Guide: Essential Tips for \(audience)"
            
            Description:
            
            Everything you need to know about growing your \(business). Perfect for \(audience) looking to build a successful business.
            
            Key tips included:
            • \(tip.capitalized)
            • Building authentic connections
            • Creating consistent value
            
            Save this pin for later! 📌
            
            #\(businessTag) #BusinessTips #SmallBusiness #Entrepreneur #MarketingStrategy
            """,
            """
            Pin Title: "\(business) Quick Start Checklist"
            
            Description:
            
            Save this quick checklist! Perfect for \(audience) who want to grow their business.
            
            ✅ \(steps[0])
            ✅ \(steps[1])
            ✅ \(steps[2])
            
            Follow for more \(business) tips and free resources!
            
            #Checklist #BusinessTips #\(businessTag) #Guide #SmallBusinessTips
            """,
            """
            Pin Title: "\(business) Tip: \(tip.capitalized)"
            
            Description:
            
            Quick tip for \(audience): \(tip.capitalized).
            
            This simple mindset shift can help you build a more successful \(business).
            
            Save and share with your network! 💡
            
            #BusinessTips #\(businessTag) #Strategy #QuickTips #BusinessAdvice
            """
        ]
    }
    
    private func generateEmailContent(business: String, audience: String, tone: MarketingTone) -> [String] {
        let tips = getBusinessSpecificTips(business: business)
        let tip = tips.randomElement() ?? "consistency is everything"
        let steps = getBusinessSpecificSteps(business: business)
        
        return [
            """
            Subject: Quick tip for your \(business)
            
            Hi there,
            
            As a \(business) owner serving \(audience), I wanted to share something that's been game-changing for us:
            
            \(tip.capitalized).
            
            Here's why this matters:
            • It builds trust with your \(audience)
            • It creates predictable results
            • It simplifies decision-making
            
            Try it out for the next 30 days and let me know what you think!
            
            Best,
            [Your name]
            
            P.S. Small consistent actions beat perfect planning every time.
            """,
            """
            Subject: One thing that could transform your \(business)
            
            Hey there,
            
            Quick email today to share something we discovered that's helping \(audience) achieve better results:
            
            \(tip.capitalized).
            
            This might sound simple, but implementing this one principle has made the biggest difference in how we serve our \(audience).
            
            Want to learn more about how to apply this to your \(business)?
            
            Reply to this email and let's chat.
            
            Talk soon,
            [Your name]
            """,
            """
            Subject: New resource for \(audience)
            
            Hi there,
            
            We just created something special for our \(audience) community:
            
            A quick-start guide with 3 actionable steps you can take this week:
            
            1. \(steps[0])
            2. \(steps[1])
            3. \(steps[2])
            
            These simple actions can help you grow your \(business) and better serve your \(audience).
            
            Want the full guide? Reply "yes" and I'll send it over.
            
            Hope this helps!
            
            [Your name]
            """
        ]
    }
    
    private func generateHashtags(business: String) -> String {
        let businessTags = business.components(separatedBy: " ").map { "#\($0.replacingOccurrences(of: "-", with: ""))" }.joined(separator: " ")
        let commonTags = "#MarketingTips #SmallBusiness #Entrepreneur #BusinessGrowth #DigitalMarketing"
        return "\(businessTags) \(commonTags)"
    }

    func saveToCalendar(text: String, userId: String, brandId: String?) async {
        guard !text.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        let item = ContentCalendarItem(
            userId: userId,
            brandId: brandId,
            date: Date(),
            platform: platform.rawValue,
            title: "Generated Content",
            notes: text
        )
        do {
            _ = try await service.saveCalendarItem(item)
            statusMessage = "Saved to marketing calendar."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
