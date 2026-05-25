import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    let placeholder: String
    var surfaceColor: Color = Color(.secondarySystemGroupedBackground)
    var onSearch: ((String) -> Void)? = nil

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(placeholder, text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    onSearch?(searchText)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onSearch?("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SearchableCalendarView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ContentCalendarViewModel
    @State private var searchText: String = ""
    @State private var selectedFilter: CalendarFilter = .all
    @State private var selectedItem: ContentCalendarItem?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    enum CalendarFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case upcoming = "Upcoming"
        case past = "Past"

        var iconName: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .today: return "sun.max"
            case .thisWeek: return "calendar"
            case .thisMonth: return "calendar.badge.clock"
            case .upcoming: return "arrow.right.circle"
            case .past: return "clock.arrow.circlepath"
            }
        }
    }

    init(service: CloudKitService? = nil, socialMediaService: SocialMediaService? = nil) {
        let cloudKitService = service ?? CloudKitService()
        let socialService = socialMediaService ?? SocialMediaService(cloudKitService: cloudKitService)
        _viewModel = StateObject(wrappedValue: ContentCalendarViewModel(service: cloudKitService, socialMediaService: socialService))
    }

    var filteredItems: [ContentCalendarItem] {
        var items = appViewModel.calendarItems

        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.notes.localizedCaseInsensitiveContains(searchText) ||
                item.platform.localizedCaseInsensitiveContains(searchText)
            }
        }

        items = applyTimeFilter(items, filter: selectedFilter)
        return items.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchView(searchText: $searchText, placeholder: "Search calendar items...", surfaceColor: colors.surface)
                .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CalendarFilter.allCases, id: \.self) { filter in
                        HubFilterChip(
                            title: filter.rawValue,
                            icon: filter.iconName,
                            isSelected: selectedFilter == filter,
                            accent: colors.primary,
                            surface: colors.surface,
                            action: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            if !searchText.isEmpty || selectedFilter != .all {
                HStack {
                    Text("\(filteredItems.count) result\(filteredItems.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }

            if filteredItems.isEmpty {
                HubEmptyState(
                    icon: searchText.isEmpty ? "magnifyingglass" : "tray",
                    title: searchText.isEmpty ? "No items found" : "No results",
                    message: searchText.isEmpty
                        ? "Try adjusting your filters or add items to your calendar."
                        : "No results for \"\(searchText)\".",
                    actionTitle: searchText.isEmpty ? nil : "Clear Search",
                    action: searchText.isEmpty ? nil : { searchText = "" }
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedFilteredItems.keys.sorted(), id: \.self) { date in
                        Section(header: Text(DateFormatter.shortDate.string(from: date))) {
                            ForEach(groupedFilteredItems[date] ?? []) { item in
                                CalendarItemRow(item: item) {
                                    selectedItem = item
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .hubScreenBackground(colors)
        .navigationTitle("Search Calendar")
        .sheet(item: $selectedItem) { item in
            CalendarItemDetailView(item: item)
                .environmentObject(appViewModel)
        }
        .task {
            if let userId = appViewModel.userProfile?.userId {
                await viewModel.loadAccounts(userId: userId)
            }
        }
    }

    private var groupedFilteredItems: [Date: [ContentCalendarItem]] {
        Dictionary(grouping: filteredItems) { item in
            Calendar.current.startOfDay(for: item.date)
        }
    }

    private func applyTimeFilter(_ items: [ContentCalendarItem], filter: CalendarFilter) -> [ContentCalendarItem] {
        let calendar = Calendar.current
        let now = Date()

        switch filter {
        case .all:
            return items
        case .today:
            return items.filter { calendar.isDateInToday($0.date) }
        case .thisWeek:
            return items.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .thisMonth:
            return items.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .upcoming:
            return items.filter { $0.date > now }
        case .past:
            return items.filter { $0.date < now }
        }
    }
}

struct SearchableSavedContent: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText: String = ""
    @State private var favorites: [[String: String]] = []

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var filteredFavorites: [[String: String]] {
        if searchText.isEmpty {
            return favorites
        }
        return favorites.filter { favorite in
            let content = favorite["content"] ?? ""
            let platform = favorite["platform"] ?? ""
            return content.localizedCaseInsensitiveContains(searchText) ||
                   platform.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchView(searchText: $searchText, placeholder: "Search saved content...", surfaceColor: colors.surface)
                .padding()

            if filteredFavorites.isEmpty {
                HubEmptyState(
                    icon: "heart.slash",
                    title: searchText.isEmpty ? "No saved content" : "No results found",
                    message: searchText.isEmpty
                        ? "Favorite generated content to see it here."
                        : "Try a different search term."
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(filteredFavorites.enumerated()), id: \.offset) { _, favorite in
                        SavedContentRow(favorite: favorite, themePrimary: colors.primary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .hubScreenBackground(colors)
        .navigationTitle("Saved Content")
        .onAppear {
            loadFavorites()
        }
    }

    private func loadFavorites() {
        favorites = UserDefaults.standard.array(forKey: "savedContentFavorites") as? [[String: String]] ?? []
    }
}

struct SavedContentRow: View {
    let favorite: [String: String]
    var themePrimary: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HubPlatformChip(
                    platform: favorite["platform"] ?? "Unknown",
                    accent: HubPlatformColors.accent(for: favorite["platform"] ?? "", themePrimary: themePrimary)
                )

                Spacer()

                if let dateString = favorite["date"],
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    Text(date, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(favorite["content"] ?? "")
                .font(.subheadline)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}
