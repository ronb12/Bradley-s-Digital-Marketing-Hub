import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    let placeholder: String
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
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Searchable Content Calendar View

struct SearchableCalendarView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: ContentCalendarViewModel
    @State private var searchText: String = ""
    @State private var selectedFilter: CalendarFilter = .all
    @State private var showFilters = false
    
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
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.notes.localizedCaseInsensitiveContains(searchText) ||
                item.platform.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply time filter
        items = applyTimeFilter(items, filter: selectedFilter)
        
        return items.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchView(searchText: $searchText, placeholder: "Search calendar items...")
                .padding()
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CalendarFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            icon: filter.iconName,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Results Count
            if !searchText.isEmpty || selectedFilter != .all {
                HStack {
                    Text("\(filteredItems.count) result\(filteredItems.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Calendar Items List
            if filteredItems.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedFilteredItems.keys.sorted(), id: \.self) { date in
                        Section(header: Text(DateFormatter.shortDate.string(from: date))) {
                            ForEach(groupedFilteredItems[date] ?? []) { item in
                                CalendarItemRow(item: item) {
                                    // Handle tap
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Search Calendar")
        .task {
            if let userId = appViewModel.userProfile?.userId {
                await viewModel.loadAccounts(userId: userId)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "magnifyingglass" : "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No items found" : "No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Button("Clear Search") {
                    searchText = ""
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Searchable Content Generator View

struct SearchableSavedContent: View {
    @State private var searchText: String = ""
    @State private var favorites: [[String: String]] = []
    
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
            SearchView(searchText: $searchText, placeholder: "Search saved content...")
                .padding()
            
            if filteredFavorites.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(Array(filteredFavorites.enumerated()), id: \.offset) { index, favorite in
                        SavedContentRow(favorite: favorite)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Saved Content")
        .onAppear {
            loadFavorites()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No saved content" : "No results found")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func loadFavorites() {
        favorites = UserDefaults.standard.array(forKey: "savedContentFavorites") as? [[String: String]] ?? []
    }
}

struct SavedContentRow: View {
    let favorite: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(favorite["platform"] ?? "Unknown")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
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

