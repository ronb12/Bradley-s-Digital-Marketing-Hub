import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showBooking = false
    @State private var selectedAffiliateURL: URL?
    @State private var selectedReviewPost: ScheduledPost?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    private var upcomingCount: Int {
        appViewModel.calendarItems.filter { $0.date > Date() }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let banner = appViewModel.demoModeBanner {
                    demoBanner(banner)
                }
                header
                metricsRow
                if !appViewModel.readyToSharePosts.isEmpty {
                    readyToShareSection
                }
                if !appViewModel.todaysCalendarItems.isEmpty {
                    todaySection
                }
                if appViewModel.currentTier == .free {
                    upgradeBanner
                }
                quickActions
                bookConsultationCard
                campaignSummary
                affiliateHighlight
            }
            .padding()
        }
        .background(colors.background.ignoresSafeArea())
        .refreshable {
            await appViewModel.refreshPortal()
        }
        .navigationTitle("Home")
        .accessibilityIdentifier("dashboard_screen")
        .sheet(isPresented: $showBooking) {
            BookingView(service: appViewModel.cloudKitService)
                .environmentObject(appViewModel)
        }
        .sheet(item: $selectedReviewPost) { post in
            PostReviewView(post: post, service: appViewModel.socialMediaService)
        }
        .sheet(isPresented: Binding(
            get: { selectedAffiliateURL != nil },
            set: { if !$0 { selectedAffiliateURL = nil } }
        )) {
            if let url = selectedAffiliateURL {
                SafariView(url: url)
            }
        }
        .task {
            if appViewModel.scheduledPosts.isEmpty && !appViewModel.isDemoMode {
                await appViewModel.refreshPortal()
            }
        }
    }

    private func demoBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .foregroundColor(colors.primary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .hubPanelStyle(colors: colors)
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

            Text("Plan, get reminded, share manually — your publishing command center")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            HubMetricCard(
                title: "Ready",
                value: "\(appViewModel.readyToSharePosts.count)",
                icon: "square.and.arrow.up",
                color: colors.accent
            )
            HubMetricCard(
                title: "Scheduled",
                value: "\(appViewModel.calendarItems.count)",
                icon: "calendar",
                color: colors.primary
            )
            HubMetricCard(
                title: "Streak",
                value: "\(appViewModel.planningStreakDays)d",
                icon: "flame.fill",
                color: colors.secondary
            )
        }
    }

    private var readyToShareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader("Ready to share", subtitle: "Tap to review and publish via Share Sheet")

            ForEach(appViewModel.readyToSharePosts.prefix(3)) { post in
                Button {
                    selectedReviewPost = post
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.platform)
                                .font(.subheadline.bold())
                            Text(post.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                ScheduledPostsView(service: appViewModel.socialMediaService)
            } label: {
                Text("View all scheduled posts")
                    .font(.caption)
            }
        }
        .hubCardStyle(colors: colors)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader("Today's schedule")

            ForEach(appViewModel.todaysCalendarItems.prefix(3)) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.bold())
                        Text(item.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HubPlatformChip(
                        platform: item.platform,
                        accent: HubPlatformColors.accent(for: item.platform, themePrimary: colors.primary)
                    )
                }
            }
        }
        .hubCardStyle(colors: colors)
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

    private var bookConsultationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HubSectionHeader("Need expert help?", subtitle: "Book a strategy session with Bradley Virtual Solutions")
            Button("Book a consultation") {
                showBooking = true
            }
            .buttonStyle(.bordered)
        }
        .hubCardStyle(colors: colors)
    }

    private var campaignSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HubSectionHeader("Campaigns Overview")
            Text("\(appViewModel.campaignPlans.count) saved plans • \(upcomingCount) upcoming items")
                .foregroundColor(.secondary)
            NavigationLink {
                AnalyticsDashboardView()
            } label: {
                Text("Open Planning Analytics")
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
                    Label("Browse recommended tools", systemImage: "link")
                }
            }
        }
        .hubCardStyle(colors: colors)
    }
}
