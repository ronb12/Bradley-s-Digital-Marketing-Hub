import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var selectedPeriod: AnalyticsPeriod = .last7Days

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    init() {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodSelector
                keyMetricsSection
                engagementChart
                platformPerformance
                contentPerformance
                bestTimesSection
            }
            .padding()
        }
        .hubScreenBackground(colors)
        .navigationTitle("Analytics")
        .task {
            await viewModel.loadAnalytics(calendarItems: appViewModel.calendarItems)
        }
    }

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { _, newValue in
            Task {
                await viewModel.loadAnalytics(calendarItems: appViewModel.calendarItems, period: newValue)
            }
        }
    }

    private var keyMetricsSection: some View {
        VStack(spacing: 12) {
            HubSectionHeader("Key Metrics")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HubMetricCard(
                    title: "Total Posts",
                    value: "\(viewModel.totalPosts)",
                    icon: "square.text.square.fill",
                    color: colors.primary
                )
                HubMetricCard(
                    title: "Scheduled",
                    value: "\(viewModel.scheduledPosts)",
                    icon: "calendar.badge.clock",
                    color: colors.accent
                )
                HubMetricCard(
                    title: "Platforms",
                    value: "\(viewModel.platformCount)",
                    icon: "app.badge.fill",
                    color: colors.secondary
                )
                HubMetricCard(
                    title: "Avg Per Week",
                    value: String(format: "%.1f", viewModel.averagePostsPerWeek),
                    icon: "chart.bar.fill",
                    color: colors.primary
                )
            }
        }
    }

    private var engagementChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Posts Over Time")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart(viewModel.postsByDate, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Posts", item.count)
                    )
                    .foregroundStyle(colors.primary.gradient)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.postsByDate, id: \.date) { item in
                        HStack {
                            Text(item.date, format: .dateTime.month().day())
                                .font(.caption)
                            Spacer()
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(colors.primary)
                                    .frame(width: CGFloat(item.count) * 20, height: 20)
                                Text("\(item.count)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .hubPanelStyle(colors: colors)
    }

    private var platformPerformance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Platform Distribution")
                .font(.headline)

            ForEach(viewModel.platformDistribution, id: \.platform) { item in
                PlatformPerformanceRow(
                    platform: item.platform,
                    count: item.count,
                    percentage: item.percentage,
                    themePrimary: colors.primary
                )
            }
        }
        .hubPanelStyle(colors: colors)
    }

    private var contentPerformance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performing Content")
                .font(.headline)

            if viewModel.topContent.isEmpty {
                HubEmptyState(
                    icon: "doc.text.magnifyingglass",
                    title: "No content yet",
                    message: "Schedule posts in your calendar to see performance insights here."
                )
            } else {
                ForEach(viewModel.topContent.prefix(5)) { item in
                    ContentPerformanceRow(item: item)
                }
            }
        }
        .hubPanelStyle(colors: colors)
    }

    private var bestTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Times to Post")
                .font(.headline)

            if viewModel.bestPostingTimes.isEmpty {
                HubEmptyState(
                    icon: "clock.arrow.circlepath",
                    title: "Analyzing patterns",
                    message: "Schedule more posts to unlock personalized best-time recommendations."
                )
            } else {
                ForEach(viewModel.bestPostingTimes, id: \.day) { time in
                    BestTimeRow(day: time.day, hour: time.hour, count: time.count)
                }
            }
        }
        .hubPanelStyle(colors: colors)
    }
}

struct PlatformPerformanceRow: View {
    let platform: String
    let count: Int
    let percentage: Double
    var themePrimary: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(platform)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(platformColor)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            Text("\(Int(percentage))% of total posts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var platformColor: Color {
        HubPlatformColors.accent(for: platform, themePrimary: themePrimary)
    }
}

struct ContentPerformanceRow: View {
    let item: ContentAnalyticsItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(item.platform)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.date, format: .dateTime.month().day())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct BestTimeRow: View {
    let day: String
    let hour: Int
    let count: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formatHour(hour))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text("\(count) posts")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var totalPosts: Int = 0
    @Published var scheduledPosts: Int = 0
    @Published var platformCount: Int = 0
    @Published var averagePostsPerWeek: Double = 0
    @Published var postsByDate: [PostDateCount] = []
    @Published var platformDistribution: [PlatformDistribution] = []
    @Published var topContent: [ContentAnalyticsItem] = []
    @Published var bestPostingTimes: [BestPostingTime] = []

    func loadAnalytics(calendarItems: [ContentCalendarItem], period: AnalyticsPeriod = .last7Days) async {
        let filteredItems = filterItems(calendarItems, period: period)

        totalPosts = filteredItems.count
        scheduledPosts = filteredItems.filter { $0.date > Date() }.count
        platformCount = Set(filteredItems.map { $0.platform }).count

        let calendar = Calendar.current
        if let startDate = calendar.date(byAdding: .day, value: -period.days, to: Date()) {
            let weeks = Double(period.days) / 7.0
            averagePostsPerWeek = weeks > 0 ? Double(totalPosts) / weeks : 0
        }

        postsByDate = calculatePostsByDate(filteredItems)
        platformDistribution = calculatePlatformDistribution(filteredItems)

        topContent = filteredItems.map { item in
            ContentAnalyticsItem(
                id: item.id,
                title: item.title,
                platform: item.platform,
                date: item.date
            )
        }.sorted { $0.date > $1.date }

        bestPostingTimes = calculateBestPostingTimes(filteredItems)
    }

    private func filterItems(_ items: [ContentCalendarItem], period: AnalyticsPeriod) -> [ContentCalendarItem] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -period.days, to: Date()) else {
            return items
        }
        return items.filter { $0.date >= startDate }
    }

    private func calculatePostsByDate(_ items: [ContentCalendarItem]) -> [PostDateCount] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.date)
        }

        return grouped.map { date, items in
            PostDateCount(date: date, count: items.count)
        }.sorted { $0.date < $1.date }
    }

    private func calculatePlatformDistribution(_ items: [ContentCalendarItem]) -> [PlatformDistribution] {
        let grouped = Dictionary(grouping: items) { $0.platform }
        let total = Double(items.count)

        return grouped.map { platform, items in
            let count = items.count
            let percentage = total > 0 ? (Double(count) / total) * 100 : 0
            return PlatformDistribution(platform: platform, count: count, percentage: percentage)
        }.sorted { $0.count > $1.count }
    }

    private func calculateBestPostingTimes(_ items: [ContentCalendarItem]) -> [BestPostingTime] {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        var dayHourCounts: [String: [Int: Int]] = [:]

        for item in items {
            let day = dayFormatter.string(from: item.date)
            let hour = calendar.component(.hour, from: item.date)

            if dayHourCounts[day] == nil {
                dayHourCounts[day] = [:]
            }
            dayHourCounts[day]?[hour, default: 0] += 1
        }

        var bestTimes: [BestPostingTime] = []

        for (day, hourCounts) in dayHourCounts {
            if let (hour, count) = hourCounts.max(by: { $0.value < $1.value }) {
                bestTimes.append(BestPostingTime(day: day, hour: hour, count: count))
            }
        }

        return bestTimes.sorted { $0.count > $1.count }
    }
}

enum AnalyticsPeriod: CaseIterable {
    case last7Days
    case last30Days
    case last90Days
    case allTime

    var displayName: String {
        switch self {
        case .last7Days: return "7 Days"
        case .last30Days: return "30 Days"
        case .last90Days: return "90 Days"
        case .allTime: return "All Time"
        }
    }

    var days: Int {
        switch self {
        case .last7Days: return 7
        case .last30Days: return 30
        case .last90Days: return 90
        case .allTime: return Int.max
        }
    }
}

struct PostDateCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct PlatformDistribution: Identifiable {
    let id = UUID()
    let platform: String
    let count: Int
    let percentage: Double
}

struct ContentAnalyticsItem: Identifiable {
    let id: String
    let title: String
    let platform: String
    let date: Date
}

struct BestPostingTime {
    let day: String
    let hour: Int
    let count: Int
}
