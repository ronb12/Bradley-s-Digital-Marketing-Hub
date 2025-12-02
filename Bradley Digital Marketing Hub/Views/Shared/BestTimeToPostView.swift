import SwiftUI
import Charts

struct BestTimeToPostView: View {
    @StateObject private var viewModel = BestTimeToPostViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedPlatform: MarketingPlatform = .instagram
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Platform Selector
                    platformSelector
                    
                    // Best Times Summary
                    bestTimesSummary
                    
                    // Day of Week Analysis
                    dayOfWeekAnalysis
                    
                    // Hourly Analysis
                    hourlyAnalysis
                    
                    // Recommendations
                    recommendations
                }
                .padding()
            }
            .navigationTitle("Best Time to Post")
            .task {
                await viewModel.analyzePostingTimes(
                    calendarItems: appViewModel.calendarItems,
                    platform: selectedPlatform
                )
            }
            .onChange(of: selectedPlatform) { oldValue, newValue in
                Task {
                    await viewModel.analyzePostingTimes(
                        calendarItems: appViewModel.calendarItems,
                        platform: newValue
                    )
                }
            }
        }
    }
    
    private var platformSelector: some View {
        Picker("Platform", selection: $selectedPlatform) {
            ForEach(MarketingPlatform.allCases) { platform in
                Text(platform.rawValue).tag(platform)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var bestTimesSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimal Posting Times")
                .font(.headline)
            
            if viewModel.optimalTimes.isEmpty {
                Text("Not enough data to analyze. Schedule more posts to get personalized recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.optimalTimes.prefix(5)) { time in
                    OptimalTimeCard(time: time, platform: selectedPlatform)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var dayOfWeekAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance by Day of Week")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(viewModel.dayPerformance) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Posts", item.postCount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.dayPerformance, id: \.day) { item in
                        HStack {
                            Text(item.day)
                                .font(.caption)
                                .frame(width: 80, alignment: .leading)
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 20)
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * CGFloat(item.postCount) / CGFloat(max(viewModel.dayPerformance.map { $0.postCount }.max() ?? 1, 1)), height: 20)
                                }
                            }
                            .frame(height: 20)
                            Text("\(item.postCount)")
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var hourlyAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance by Hour")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(viewModel.hourPerformance) { item in
                    LineMark(
                        x: .value("Hour", item.hour),
                        y: .value("Posts", item.postCount)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Hour", item.hour),
                        y: .value("Posts", item.postCount)
                    )
                    .foregroundStyle(Color.green.opacity(0.2).gradient)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .number)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.hourPerformance.prefix(12), id: \.hour) { item in
                        HStack {
                            Text("\(item.hour):00")
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: CGFloat(item.postCount) * 20, height: 16)
                            Text("\(item.postCount)")
                                .font(.caption2)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            ForEach(viewModel.recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct OptimalTimeCard: View {
    let time: OptimalPostingTime
    let platform: MarketingPlatform
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(time.dayOfWeek)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(time.hour):00")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Best Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(time.score)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct RecommendationCard: View {
    let recommendation: PostingRecommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recommendation.icon)
                .foregroundColor(recommendation.type.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - View Model

@MainActor
class BestTimeToPostViewModel: ObservableObject {
    @Published var optimalTimes: [OptimalPostingTime] = []
    @Published var dayPerformance: [DayPerformance] = []
    @Published var hourPerformance: [HourPerformance] = []
    @Published var recommendations: [PostingRecommendation] = []
    
    func analyzePostingTimes(calendarItems: [ContentCalendarItem], platform: MarketingPlatform) async {
        let platformItems = calendarItems.filter { $0.platform.lowercased() == platform.rawValue.lowercased() }
        
        guard !platformItems.isEmpty else {
            optimalTimes = []
            dayPerformance = []
            hourPerformance = []
            recommendations = generateDefaultRecommendations(for: platform)
            return
        }
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        // Analyze by day of week
        var dayCounts: [String: Int] = [:]
        for item in platformItems {
            let day = dateFormatter.string(from: item.date)
            dayCounts[day, default: 0] += 1
        }
        
        dayPerformance = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            .map { day in
                DayPerformance(day: day, postCount: dayCounts[day] ?? 0)
            }
        
        // Analyze by hour
        var hourCounts: [Int: Int] = [:]
        for item in platformItems {
            let hour = calendar.component(.hour, from: item.date)
            hourCounts[hour, default: 0] += 1
        }
        
        hourPerformance = (0...23).map { hour in
            HourPerformance(hour: hour, postCount: hourCounts[hour] ?? 0)
        }
        
        // Calculate optimal times
        optimalTimes = calculateOptimalTimes(dayCounts: dayCounts, hourCounts: hourCounts)
        
        // Generate recommendations
        recommendations = generateRecommendations(
            dayPerformance: dayPerformance,
            hourPerformance: hourPerformance,
            platform: platform
        )
    }
    
    private func calculateOptimalTimes(dayCounts: [String: Int], hourCounts: [Int: Int]) -> [OptimalPostingTime] {
        var optimal: [OptimalPostingTime] = []
        
        // Find best days
        let sortedDays = dayCounts.sorted { $0.value > $1.value }
        let sortedHours = hourCounts.sorted { $0.value > $1.value }
        
        for (index, dayEntry) in sortedDays.prefix(3).enumerated() {
            for hourEntry in sortedHours.prefix(3) {
                let score = calculateScore(dayCount: dayEntry.value, hourCount: hourEntry.value)
                optimal.append(
                    OptimalPostingTime(
                        dayOfWeek: dayEntry.key,
                        hour: hourEntry.key,
                        score: score
                    )
                )
            }
        }
        
        return optimal.sorted { $0.score > $1.score }.prefix(5).map { $0 }
    }
    
    private func calculateScore(dayCount: Int, hourCount: Int) -> Int {
        // Simple scoring: higher counts = better score
        let maxDayCount = 10.0 // Normalize to max expected
        let maxHourCount = 5.0
        
        let dayScore = Double(dayCount) / maxDayCount * 50
        let hourScore = Double(hourCount) / maxHourCount * 50
        
        return min(100, Int(dayScore + hourScore))
    }
    
    private func generateRecommendations(
        dayPerformance: [DayPerformance],
        hourPerformance: [HourPerformance],
        platform: MarketingPlatform
    ) -> [PostingRecommendation] {
        var recommendations: [PostingRecommendation] = []
        
        let bestDay = dayPerformance.max(by: { $0.postCount < $1.postCount })
        if let bestDay = bestDay, bestDay.postCount > 0 {
            recommendations.append(
                PostingRecommendation(
                    type: .timing,
                    title: "Best Day: \(bestDay.day)",
                    description: "You've posted most on \(bestDay.day). Consider this your optimal day for this platform.",
                    icon: "calendar"
                )
            )
        }
        
        let bestHour = hourPerformance.max(by: { $0.postCount < $1.postCount })
        if let bestHour = bestHour, bestHour.postCount > 0 {
            recommendations.append(
                PostingRecommendation(
                    type: .timing,
                    title: "Best Hour: \(bestHour.hour):00",
                    description: "Your highest engagement time. Schedule future posts around this time for better reach.",
                    icon: "clock"
                )
            )
        }
        
        // Platform-specific recommendations
        recommendations.append(contentsOf: generatePlatformRecommendations(for: platform))
        
        return recommendations
    }
    
    private func generatePlatformRecommendations(for platform: MarketingPlatform) -> [PostingRecommendation] {
        switch platform {
        case .instagram:
            return [
                PostingRecommendation(
                    type: .engagement,
                    title: "Instagram Best Times",
                    description: "Generally: Tuesday-Friday, 9 AM - 1 PM, and 7-9 PM EST tend to perform well.",
                    icon: "camera.fill"
                )
            ]
        case .facebook:
            return [
                PostingRecommendation(
                    type: .engagement,
                    title: "Facebook Best Times",
                    description: "Best days: Thursday-Sunday. Best hours: 9 AM, 1 PM, and 3 PM EST.",
                    icon: "hand.thumbsup.fill"
                )
            ]
        case .twitter:
            return [
                PostingRecommendation(
                    type: .engagement,
                    title: "Twitter Best Times",
                    description: "Peak times: Monday-Friday, 9 AM - 3 PM EST. Higher engagement during weekdays.",
                    icon: "at"
                )
            ]
        case .linkedin:
            return [
                PostingRecommendation(
                    type: .engagement,
                    title: "LinkedIn Best Times",
                    description: "Professional hours: Tuesday-Thursday, 8-10 AM EST. Avoid weekends and late evenings.",
                    icon: "briefcase.fill"
                )
            ]
        case .tiktok:
            return [
                PostingRecommendation(
                    type: .engagement,
                    title: "TikTok Best Times",
                    description: "Evening hours: 6-10 PM EST, especially Tuesday-Thursday. Weekends also perform well.",
                    icon: "play.rectangle.fill"
                )
            ]
        default:
            return []
        }
    }
    
    private func generateDefaultRecommendations(for platform: MarketingPlatform) -> [PostingRecommendation] {
        return generatePlatformRecommendations(for: platform) + [
            PostingRecommendation(
                type: .data,
                title: "Need More Data",
                description: "Schedule more posts to get personalized best time recommendations based on your audience.",
                icon: "chart.bar.fill"
            )
        ]
    }
}

// MARK: - Data Models

struct OptimalPostingTime: Identifiable {
    let id = UUID()
    let dayOfWeek: String
    let hour: Int
    let score: Int
}

struct DayPerformance: Identifiable {
    let id = UUID()
    let day: String
    let postCount: Int
}

struct HourPerformance: Identifiable {
    let id = UUID()
    let hour: Int
    let postCount: Int
}

struct PostingRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let icon: String
}

enum RecommendationType {
    case timing
    case engagement
    case data
    
    var color: Color {
        switch self {
        case .timing: return .blue
        case .engagement: return .green
        case .data: return .orange
        }
    }
}

