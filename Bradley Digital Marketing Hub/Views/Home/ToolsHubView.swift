import SwiftUI

struct ToolsHubView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HubSectionHeader("Insights & Tools", subtitle: "Research, analyze, export, and share")

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        NavigationLink { AnalyticsDashboardView() } label: {
                            HubActionCard(title: "Analytics", subtitle: "Performance overview", icon: "chart.bar.fill", tint: colors.primary)
                        }
                        NavigationLink { HashtagResearchView() } label: {
                            HubActionCard(title: "Hashtags", subtitle: "Tag research", icon: "number", tint: colors.secondary)
                        }
                    }
                    GridRow {
                        NavigationLink { BestTimeToPostView() } label: {
                            HubActionCard(title: "Best Times", subtitle: "Optimal schedule", icon: "clock.arrow.circlepath", tint: colors.accent)
                        }
                        NavigationLink { SearchableSavedContent() } label: {
                            HubActionCard(title: "Saved Content", subtitle: "Your favorites", icon: "heart.text.square", tint: colors.primary)
                        }
                    }
                    GridRow {
                        NavigationLink { ExportView(calendarItems: appViewModel.calendarItems) } label: {
                            HubActionCard(title: "Export", subtitle: "CSV, JSON, text", icon: "square.and.arrow.up", tint: colors.secondary)
                        }
                        NavigationLink { SocialAccountsView(service: appViewModel.socialMediaService) } label: {
                            HubActionCard(title: "Share Setup", subtitle: "Review & connect", icon: "link.circle", tint: colors.accent)
                        }
                    }
                    GridRow {
                        NavigationLink { SearchableCalendarView(service: appViewModel.cloudKitService, socialMediaService: appViewModel.socialMediaService) } label: {
                            HubActionCard(title: "Search Calendar", subtitle: "Filter & find posts", icon: "magnifyingglass", tint: colors.primary)
                        }
                        NavigationLink { AffiliateToolsView() } label: {
                            HubActionCard(title: "Affiliate Tools", subtitle: "Recommended stack", icon: "link", tint: colors.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .hubScreenBackground(colors)
        .navigationTitle("Tools")
    }
}
