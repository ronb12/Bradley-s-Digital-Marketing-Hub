import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showBooking = false
    @State private var selectedAffiliateURL: URL?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    private var upcomingCount: Int {
        appViewModel.calendarItems.filter { $0.date > Date() }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metricsRow
                if appViewModel.currentTier == .free {
                    upgradeBanner
                }
                quickActions
                campaignSummary
                affiliateHighlight
            }
            .padding()
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("Home")
        .sheet(isPresented: $showBooking) {
            BookingView(service: appViewModel.cloudKitService)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: Binding(
            get: { selectedAffiliateURL != nil },
            set: { if !$0 { selectedAffiliateURL = nil } }
        )) {
            if let url = selectedAffiliateURL {
                SafariView(url: url)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if appViewModel.isDemoMode {
                    Label("Demo", systemImage: "eye.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colors.primary.opacity(0.15), in: Capsule())
                        .foregroundColor(colors.primary)
                }
                Spacer()
                Text(appViewModel.currentTier.displayName)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(colors.primary.opacity(0.12), in: Capsule())
                    .foregroundColor(colors.primary)
            }

            Text("Welcome back, \(appViewModel.userProfile?.name ?? "creator")")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("Your content command center")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            HubMetricCard(
                title: "Campaigns",
                value: "\(appViewModel.campaignPlans.count)",
                icon: "target",
                color: colors.primary
            )
            HubMetricCard(
                title: "Scheduled",
                value: "\(appViewModel.calendarItems.count)",
                icon: "calendar",
                color: colors.secondary
            )
            HubMetricCard(
                title: "Upcoming",
                value: "\(upcomingCount)",
                icon: "clock.badge.checkmark",
                color: colors.accent
            )
        }
    }

    private var upgradeBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HubSectionHeader("Unlock Pro", subtitle: "Unlimited campaigns, premium templates, and exports")
            Button("See plans") {
                appViewModel.showPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .tint(colors.primary)
        }
        .hubCardStyle(colors: colors)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader("Create", subtitle: "Generate, plan, and schedule")
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    NavigationLink {
                        ContentGeneratorView(service: appViewModel.cloudKitService)
                    } label: {
                        HubActionCard(title: "Content Generator", subtitle: "Platform-ready captions", icon: "sparkles", tint: colors.primary)
                    }
                    NavigationLink {
                        CampaignPlannerView(service: appViewModel.cloudKitService)
                    } label: {
                        HubActionCard(title: "Campaign Planner", subtitle: "Strategy outlines", icon: "target", tint: colors.secondary)
                    }
                }
                GridRow {
                    NavigationLink {
                        ContentCalendarView(service: appViewModel.cloudKitService, socialMediaService: appViewModel.socialMediaService)
                    } label: {
                        HubActionCard(title: "Content Calendar", subtitle: "Plan your schedule", icon: "calendar", tint: colors.accent)
                    }
                    NavigationLink {
                        TemplatesView()
                    } label: {
                        HubActionCard(title: "Templates", subtitle: "Ready-to-use assets", icon: "doc.richtext", tint: colors.primary)
                    }
                }
            }
        }
    }

    private var campaignSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HubSectionHeader("Campaigns Overview")
            Text("\(appViewModel.campaignPlans.count) saved plans • \(appViewModel.calendarItems.count) calendar items")
                .foregroundColor(.secondary)
            NavigationLink {
                CampaignPlannerView(service: appViewModel.cloudKitService)
            } label: {
                Text("Open Campaign Planner")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .hubCardStyle(colors: colors)
    }

    private var affiliateHighlight: some View {
        VStack(alignment: .leading, spacing: 10) {
            HubSectionHeader("Recommended Tool")
            if let tool = appViewModel.affiliateTools.first(where: { $0.isProRecommended }) ?? appViewModel.affiliateTools.first,
               let url = URL(string: tool.url) {
                Text(tool.name).bold()
                Text(tool.shortDescription).foregroundColor(.secondary)
                Button("Open tool") {
                    selectedAffiliateURL = url
                    Task { await appViewModel.logAffiliateClick(tool: tool) }
                }
                .buttonStyle(.borderedProminent)
                .tint(colors.primary)
            } else {
                NavigationLink {
                    AffiliateToolsView()
                } label: {
                    Label("Browse affiliate tools", systemImage: "link")
                }
            }
        }
        .hubCardStyle(colors: colors)
    }
}
