import SwiftUI

struct HubSearchView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    private var calendarResults: [ContentCalendarItem] {
        guard !searchText.isEmpty else { return [] }
        return appViewModel.calendarItems.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText) ||
            $0.platform.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var campaignResults: [CampaignPlan] {
        guard !searchText.isEmpty else { return [] }
        return appViewModel.campaignPlans.filter {
            $0.goal.localizedCaseInsensitiveContains(searchText) ||
            $0.platform.localizedCaseInsensitiveContains(searchText) ||
            $0.outlineDetails.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var templateResults: [TemplateItem] {
        guard !searchText.isEmpty else { return [] }
        return appViewModel.templates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                SearchView(searchText: $searchText, placeholder: "Search calendar, campaigns, templates...")
            }

            if searchText.isEmpty {
                Section {
                    Text("Search across your calendar items, saved campaign plans, and templates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !calendarResults.isEmpty {
                Section("Calendar (\(calendarResults.count))") {
                    ForEach(calendarResults.prefix(10)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.subheadline.bold())
                            Text("\(item.platform) • \(item.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !campaignResults.isEmpty {
                Section("Campaigns (\(campaignResults.count))") {
                    ForEach(campaignResults.prefix(10)) { plan in
                        NavigationLink {
                            CampaignPlanDetailView(plan: plan)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.goal).font(.subheadline.bold())
                                Text(plan.platform)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            if !templateResults.isEmpty {
                Section("Templates (\(templateResults.count))") {
                    ForEach(templateResults.prefix(10)) { template in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name).font(.subheadline.bold())
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }

            if !searchText.isEmpty && calendarResults.isEmpty && campaignResults.isEmpty && templateResults.isEmpty {
                Section {
                    HubEmptyState(icon: "magnifyingglass", title: "No results", message: "Try a different keyword.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .hubScreenBackground(colors)
        .navigationTitle("Search")
    }
}
