import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showBooking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if appViewModel.currentTier == .free {
                    upgradeBanner
                }
                quickActions
                campaignSummary
                affiliateHighlight
            }
            .padding()
        }
        .navigationTitle("Home")
        .sheet(isPresented: $showBooking) {
            BookingView(service: appViewModel.cloudKitService)
                .environmentObject(appViewModel)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(appViewModel.userProfile?.name ?? "creator")")
                .font(.title).bold()
            Text("Current plan: \(appViewModel.currentTier.displayName)")
                .foregroundColor(.secondary)
        }
    }

    private var upgradeBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upgrade to Pro or Agency for unlimited plans and premium templates.")
            Button("See benefits") {
                appViewModel.showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .primarySectionStyle()
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Productivity Hub").font(.headline)
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    NavigationLink {
                        ContentGeneratorView(service: appViewModel.cloudKitService)
                    } label: {
                        actionCard(title: "Content Generator", subtitle: "3-5 caption ideas", icon: "sparkles")
                    }
                    NavigationLink {
                        CampaignPlannerView(service: appViewModel.cloudKitService)
                    } label: {
                        actionCard(title: "Campaign Planner", subtitle: "Outline goals", icon: "target")
                    }
                }
                GridRow {
                    NavigationLink {
                        ContentCalendarView(service: appViewModel.cloudKitService)
                    } label: {
                        actionCard(title: "Content Calendar", subtitle: "Schedule posts", icon: "calendar")
                    }
                    NavigationLink {
                        TemplatesView()
                    } label: {
                        actionCard(title: "Templates", subtitle: "Ready-to-use", icon: "doc.richtext")
                    }
                }
                GridRow {
                    NavigationLink {
                        AffiliateToolsView()
                    } label: {
                        actionCard(title: "Affiliate Tools", subtitle: "Handpicked stack", icon: "link")
                    }
                    Button {
                        showBooking = true
                    } label: {
                        actionCard(title: "Book a Service", subtitle: "Consulting + builds", icon: "person.2.wave.2")
                    }
                }
            }
        }
    }

    private func actionCard(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.hubBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var campaignSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Campaigns Overview").font(.headline)
            Text("\(appViewModel.campaignPlans.count) saved plans • \(appViewModel.calendarItems.count) calendar items")
                .foregroundColor(.secondary)
            Button("View Planner") {
                appViewModel.showPaywall = appViewModel.currentTier == .free && !(appViewModel.canAddCampaignPlan())
            }
            .buttonStyle(.bordered)
        }
        .primarySectionStyle()
    }

    private var affiliateHighlight: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Tool").font(.headline)
            if let tool = appViewModel.affiliateTools.first(where: { $0.isProRecommended }) ?? appViewModel.affiliateTools.first {
                Text(tool.name).bold()
                Text(tool.shortDescription).foregroundColor(.secondary)
                Button("Open tool") {
                    appViewModel.showPaywall = false
                }
                .buttonStyle(.bordered)
            } else {
                Text("Add affiliate tools in CloudKit public database to highlight them here.")
                    .foregroundColor(.secondary)
            }
        }
        .primarySectionStyle()
    }
}
