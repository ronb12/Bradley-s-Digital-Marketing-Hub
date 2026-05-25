import SwiftUI

struct CampaignPlansListView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        Group {
            if appViewModel.campaignPlans.isEmpty {
                HubEmptyState(
                    icon: "target",
                    title: "No campaign plans yet",
                    message: "Generate and save a plan in Campaign Planner to see it here."
                )
                .padding()
            } else {
                List {
                    ForEach(appViewModel.campaignPlans.sorted { $0.createdAt > $1.createdAt }) { plan in
                        NavigationLink {
                            CampaignPlanDetailView(plan: plan)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.goal)
                                    .font(.headline)
                                Text(plan.platform)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Budget: $\(Int(plan.budget)) • \(plan.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .hubScreenBackground(colors)
        .navigationTitle("Campaign Plans")
    }
}

struct CampaignPlanDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let plan: CampaignPlan

    @State private var scheduleStartDate = Date().addingTimeInterval(86400)
    @State private var isScheduling = false
    @State private var statusMessage: String?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    private var hookIdeas: [String] {
        CampaignPlanParser.hookIdeas(from: plan.outlineDetails)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.goal)
                        .font(.title2.bold())
                    HStack {
                        HubPlatformChip(
                            platform: plan.platform,
                            accent: HubPlatformColors.accent(for: plan.platform, themePrimary: colors.primary)
                        )
                        Text("$\(Int(plan.budget)) budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(plan.outlineDetails)
                    .font(.body)
                    .hubPanelStyle(colors: colors)

                if !hookIdeas.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HubSectionHeader("Schedule hooks to calendar", subtitle: "Creates one calendar item per hook with reminders")

                        DatePicker("First post date", selection: $scheduleStartDate, displayedComponents: [.date, .hourAndMinute])

                        ForEach(Array(hookIdeas.prefix(5).enumerated()), id: \.offset) { index, hook in
                            Text("\(index + 1). \(hook)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Button {
                            Task { await scheduleHooks() }
                        } label: {
                            if isScheduling {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("Schedule \(min(hookIdeas.count, 5)) posts", systemImage: "calendar.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(colors.primary)
                        .disabled(isScheduling || appViewModel.isDemoMode)

                        if let statusMessage {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .hubCardStyle(colors: colors)
                }
            }
            .padding()
        }
        .hubScreenBackground(colors)
        .navigationTitle("Campaign Plan")
    }

    private func scheduleHooks() async {
        guard appViewModel.canAddCalendarItem() || hookIdeas.count <= (appViewModel.currentTier.maxCalendarItems.map { $0 - appViewModel.calendarItems.count } ?? Int.max) else {
            appViewModel.showPaywall = true
            statusMessage = "Calendar limit reached — upgrade for unlimited scheduling."
            return
        }

        isScheduling = true
        defer { isScheduling = false }

        do {
            let count = try await appViewModel.scheduleHooksFromCampaignPlan(plan, startDate: scheduleStartDate)
            statusMessage = "Scheduled \(count) post(s) with reminders. Check Home when they're due."
            HapticFeedback.success()
        } catch {
            statusMessage = error.localizedDescription
            if error.localizedDescription.contains("limit") {
                appViewModel.showPaywall = true
            }
        }
    }
}
