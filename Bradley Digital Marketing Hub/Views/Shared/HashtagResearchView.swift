import SwiftUI

struct HashtagResearchView: View {
    @State private var searchText: String = ""
    @State private var selectedPlatform: MarketingPlatform = .instagram
    @StateObject private var viewModel = HashtagResearchViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Platform", selection: $selectedPlatform) {
                        ForEach(MarketingPlatform.allCases) { platform in
                            Text(platform.rawValue).tag(platform)
                        }
                    }
                    
                    TextField("Enter topic or keyword", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Button {
                        Task {
                            await viewModel.researchHashtags(for: searchText, platform: selectedPlatform)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Research Hashtags")
                        }
                    }
                    .disabled(searchText.isEmpty)
                } header: {
                    Text("Search")
                }
                
                if !viewModel.researchedHashtags.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Hashtags")
                                .font(.headline)
                            
                            HashtagCloud(hashtags: viewModel.researchedHashtags) { hashtag in
                                UIPasteboard.general.string = hashtag
                                viewModel.showCopiedMessage = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    viewModel.showCopiedMessage = false
                                }
                            }
                        }
                    } header: {
                        Text("Results")
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hashtag Insights")
                                .font(.headline)
                            
                            ForEach(viewModel.hashtagInsights) { insight in
                                InsightRow(insight: insight)
                            }
                        }
                    } header: {
                        Text("Best Practices")
                    }
                }
                
                if viewModel.showCopiedMessage {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Copied to clipboard!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Hashtag Research")
        }
    }
}

struct HashtagCloud: View {
    let hashtags: [HashtagInfo]
    let onTap: (String) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(hashtags) { hashtag in
                HashtagChip(hashtag: hashtag, onTap: onTap)
            }
        }
    }
}

struct HashtagChip: View {
    let hashtag: HashtagInfo
    let onTap: (String) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            onTap(hashtag.text)
        }) {
            HStack(spacing: 4) {
                Text(hashtag.text)
                    .font(.caption)
                if hashtag.estimatedReach > 0 {
                    Text("• \(formatReach(hashtag.estimatedReach))")
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(hashtag.category.color.opacity(0.1))
            .foregroundColor(hashtag.category.color)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(hashtag.category.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatReach(_ reach: Int) -> String {
        if reach >= 1_000_000 {
            return String(format: "%.1fM", Double(reach) / 1_000_000.0)
        } else if reach >= 1_000 {
            return String(format: "%.1fK", Double(reach) / 1_000.0)
        } else {
            return "\(reach)"
        }
    }
}

struct InsightRow: View {
    let insight: HashtagInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: insight.icon)
                    .foregroundColor(insight.type.color)
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxWidthUsed: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxWidthUsed = max(maxWidthUsed, currentX - spacing)
            }
            
            self.size = CGSize(width: maxWidthUsed, height: currentY + lineHeight)
        }
    }
}

// MARK: - View Model

@MainActor
class HashtagResearchViewModel: ObservableObject {
    @Published var researchedHashtags: [HashtagInfo] = []
    @Published var hashtagInsights: [HashtagInsight] = []
    @Published var showCopiedMessage = false
    
    func researchHashtags(for topic: String, platform: MarketingPlatform) async {
        // Generate hashtag suggestions based on topic and platform
        let hashtags = generateHashtags(for: topic, platform: platform)
        researchedHashtags = hashtags
        
        // Generate insights
        hashtagInsights = generateInsights(for: platform)
    }
    
    private func generateHashtags(for topic: String, platform: MarketingPlatform) -> [HashtagInfo] {
        let baseHashtags = [
            "#\(topic.lowercased().replacingOccurrences(of: " ", with: ""))",
            "#\(topic.lowercased().replacingOccurrences(of: " ", with: "_"))",
            "#\(topic.lowercased().replacingOccurrences(of: " ", with: ""))tips",
            "#\(topic.lowercased().replacingOccurrences(of: " ", with: ""))life"
        ]
        
        let platformSpecific = platformHashtags(for: platform)
        let categoryHashtags = categoryHashtags(for: topic)
        
        var allHashtags = (baseHashtags + platformSpecific + categoryHashtags).map { hashtag in
            HashtagInfo(
                text: hashtag,
                category: categorizeHashtag(hashtag),
                estimatedReach: Int.random(in: 1000...10000000)
            )
        }
        
        // Remove duplicates and limit to 30
        var seen = Set<String>()
        allHashtags = allHashtags.filter { seen.insert($0.text).inserted }.prefix(30).map { $0 }
        
        return Array(allHashtags)
    }
    
    private func platformHashtags(for platform: MarketingPlatform) -> [String] {
        switch platform {
        case .instagram:
            return ["#instagram", "#instagood", "#photooftheday", "#love", "#like4like", "#followme", "#picoftheday"]
        case .facebook:
            return ["#facebook", "#socialmedia", "#marketing", "#business", "#entrepreneur"]
        case .linkedin:
            return ["#linkedin", "#networking", "#business", "#career", "#professional", "#leadership"]
        case .twitter:
            return ["#twitter", "#tweet", "#trending", "#news", "#viral"]
        case .tiktok:
            return ["#tiktok", "#fyp", "#viral", "#foryou", "#foryoupage", "#trending"]
        case .youtube:
            return ["#youtube", "#subscribe", "#video", "#youtuber", "#vlog"]
        case .pinterest:
            return ["#pinterest", "#pin", "#diy", "#home", "#inspiration"]
        case .email:
            return []
        }
    }
    
    private func categoryHashtags(for topic: String) -> [String] {
        let lowerTopic = topic.lowercased()
        
        if lowerTopic.contains("marketing") || lowerTopic.contains("business") {
            return ["#marketing", "#business", "#entrepreneur", "#startup", "#success", "#growth"]
        } else if lowerTopic.contains("fitness") || lowerTopic.contains("health") {
            return ["#fitness", "#health", "#wellness", "#workout", "#gym", "#motivation"]
        } else if lowerTopic.contains("food") || lowerTopic.contains("cooking") {
            return ["#food", "#foodie", "#cooking", "#recipe", "#delicious", "#yummy"]
        } else if lowerTopic.contains("travel") {
            return ["#travel", "#wanderlust", "#adventure", "#explore", "#vacation"]
        } else {
            return ["#lifestyle", "#daily", "#inspiration", "#motivation"]
        }
    }
    
    private func categorizeHashtag(_ hashtag: String) -> HashtagCategory {
        let lower = hashtag.lowercased()
        
        if lower.contains("marketing") || lower.contains("business") || lower.contains("entrepreneur") {
            return .business
        } else if lower.contains("fitness") || lower.contains("health") || lower.contains("wellness") {
            return .lifestyle
        } else if lower.contains("food") || lower.contains("cooking") || lower.contains("recipe") {
            return .food
        } else if lower.contains("travel") || lower.contains("wanderlust") {
            return .travel
        } else {
            return .general
        }
    }
    
    private func generateInsights(for platform: MarketingPlatform) -> [HashtagInsight] {
        var insights: [HashtagInsight] = []
        
        switch platform {
        case .instagram:
            insights = [
                HashtagInsight(
                    type: .optimalCount,
                    title: "Optimal Hashtag Count",
                    description: "Use 5-10 hashtags for best engagement. Mix popular (1M+ posts) and niche (10K-500K posts) hashtags.",
                    icon: "number.circle.fill"
                ),
                HashtagInsight(
                    type: .placement,
                    title: "Hashtag Placement",
                    description: "Place hashtags in the first comment or at the end of your caption for cleaner appearance.",
                    icon: "textformat"
                ),
                HashtagInsight(
                    type: .research,
                    title: "Research Tools",
                    description: "Use Instagram's search to find related hashtags and see post counts before using them.",
                    icon: "magnifyingglass"
                )
            ]
        case .twitter:
            insights = [
                HashtagInsight(
                    type: .optimalCount,
                    title: "Optimal Hashtag Count",
                    description: "Use 1-2 hashtags for best engagement. More hashtags can reduce engagement.",
                    icon: "number.circle.fill"
                ),
                HashtagInsight(
                    type: .placement,
                    title: "Trending Hashtags",
                    description: "Monitor trending topics and join relevant conversations with appropriate hashtags.",
                    icon: "flame.fill"
                )
            ]
        default:
            insights = [
                HashtagInsight(
                    type: .optimalCount,
                    title: "Hashtag Best Practices",
                    description: "Use relevant, platform-specific hashtags. Research what works best for your audience.",
                    icon: "lightbulb.fill"
                )
            ]
        }
        
        return insights
    }
}

// MARK: - Data Models

struct HashtagInfo: Identifiable {
    let id = UUID()
    let text: String
    let category: HashtagCategory
    let estimatedReach: Int
}

enum HashtagCategory {
    case general
    case business
    case lifestyle
    case food
    case travel
    
    var color: Color {
        switch self {
        case .general: return .gray
        case .business: return .blue
        case .lifestyle: return .purple
        case .food: return .orange
        case .travel: return .cyan
        }
    }
}

struct HashtagInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let icon: String
}

enum InsightType {
    case optimalCount
    case placement
    case research
    case timing
    
    var color: Color {
        switch self {
        case .optimalCount: return .blue
        case .placement: return .green
        case .research: return .orange
        case .timing: return .purple
        }
    }
}

