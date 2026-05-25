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
                HubSectionHeader("Insights & Tools", subtitle: "Research, analyze, export, and share manually")

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        NavigationLink { AnalyticsDashboardView() } label: {
                            HubActionCard(title: "Planning Analytics", subtitle: "Calendar schedule stats", icon: "chart.bar.fill", tint: colors.primary)
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
                        NavigationLink { HubSearchView() } label: {
                            HubActionCard(title: "Search All", subtitle: "Calendar, campaigns, templates", icon: "magnifyingglass", tint: colors.primary)
                        }
                        NavigationLink { ExportView(calendarItems: appViewModel.calendarItems) } label: {
                            HubActionCard(title: "Export", subtitle: appViewModel.currentTier == .free ? "Pro feature" : "CSV, JSON, text", icon: "square.and.arrow.up", tint: colors.secondary)
                        }
                        .disabled(appViewModel.currentTier == .free)
                        .simultaneousGesture(TapGesture().onEnded {
                            if appViewModel.currentTier == .free { appViewModel.showPaywall = true }
                        })
                    }
                    GridRow {
                        NavigationLink { SocialAccountsView(service: appViewModel.socialMediaService) } label: {
                            HubActionCard(title: "Share Setup", subtitle: "Manual share guide", icon: "link.circle", tint: colors.accent)
                        }
                        NavigationLink { HelpCenterView() } label: {
                            HubActionCard(title: "Help Center", subtitle: "Manual share FAQ", icon: "questionmark.circle", tint: colors.primary)
                        }
                    }
                    GridRow {
                        NavigationLink { AffiliateToolsView() } label: {
                            HubActionCard(title: "Affiliate Tools", subtitle: "Recommended stack", icon: "link", tint: colors.secondary)
                        }
                        NavigationLink { SearchableCalendarView(service: appViewModel.cloudKitService, socialMediaService: appViewModel.socialMediaService) } label: {
                            HubActionCard(title: "Calendar Search", subtitle: "Filter & find posts", icon: "calendar.badge.clock", tint: colors.accent)
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
