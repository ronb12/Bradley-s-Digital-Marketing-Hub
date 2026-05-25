import SwiftUI
import CloudKit
import UIKit

enum CalendarViewMode {
    case list
    case calendar
}

struct ContentCalendarView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ContentCalendarViewModel
    @State private var viewMode: CalendarViewMode = .list
    @State private var selectedCalendarDate: Date = Date()
    @State private var selectedItem: ContentCalendarItem?
    @State private var showItemDetail = false
    @State private var searchText = ""
    @State private var isSelecting = false
    @State private var selectedItemIDs: Set<String> = []
    @State private var showBulkActions = false
    @State private var showExport = false

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    init(service: CloudKitService? = nil, socialMediaService: SocialMediaService? = nil) {
        let cloudKitService = service ?? CloudKitService()
        let socialService = socialMediaService ?? SocialMediaService(cloudKitService: cloudKitService)
        _viewModel = StateObject(wrappedValue: ContentCalendarViewModel(service: cloudKitService, socialMediaService: socialService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // View Mode Toggle
            Picker("View", selection: $viewMode) {
                Label("List", systemImage: "list.bullet").tag(CalendarViewMode.list)
                Label("Calendar", systemImage: "calendar").tag(CalendarViewMode.calendar)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if viewMode == .calendar {
                calendarView
            } else {
                listView
            }
        }
        .hubScreenBackground(colors)
        .navigationTitle("Content Calendar")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isSelecting.toggle()
                        if !isSelecting { selectedItemIDs.removeAll() }
                    } label: {
                        Label(isSelecting ? "Done Selecting" : "Select Items", systemImage: "checkmark.circle")
                    }
                    NavigationLink {
                        SearchableCalendarView(
                            service: appViewModel.cloudKitService,
                            socialMediaService: appViewModel.socialMediaService
                        )
                    } label: {
                        Label("Advanced Search", systemImage: "magnifyingglass")
                    }
                    Button {
                        showExport = true
                    } label: {
                        Label("Export Calendar", systemImage: "square.and.arrow.up")
                    }
                    .disabled(appViewModel.currentTier == .free)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            if isSelecting {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Bulk Edit (\(selectedItemIDs.count))") {
                        showBulkActions = true
                    }
                    .disabled(selectedItemIDs.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showBulkActions) {
            BulkActionsView(selectedItems: $selectedItemIDs, calendarItems: appViewModel.calendarItems)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showExport) {
            if appViewModel.currentTier == .free {
                PaywallView()
            } else {
                ExportView(calendarItems: appViewModel.calendarItems)
            }
        }
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
    
    private var calendarView: some View {
        ScrollView {
            ContentCalendarGridView(
                selectedDate: $selectedCalendarDate,
                calendarItems: appViewModel.calendarItems,
                onItemTap: { item in
                    selectedItem = item
                }
            )
            
            // Items for selected date
            if !itemsForSelectedDate.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scheduled for \(selectedCalendarDate.formatted(.dateTime.month().day()))")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(itemsForSelectedDate) { item in
                        CalendarItemRow(item: item) {
                            selectedItem = item
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    private var listView: some View {
        List {
            Section {
                SearchView(searchText: $searchText, placeholder: "Search title, platform, or notes...")
            }

            ForEach(groupedEntries.keys.sorted(), id: \.self) { date in
                Section(header: Text(DateFormatter.shortDate.string(from: date))) {
                    ForEach(groupedEntries[date] ?? []) { item in
                        if isSelecting {
                            Button {
                                toggleSelection(item.id)
                            } label: {
                                HStack {
                                    Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedItemIDs.contains(item.id) ? colors.primary : .secondary)
                                    calendarListRow(item)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                selectedItem = item
                            } label: {
                                calendarListRow(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Section(header: Text("Scheduled Posts")) {
                NavigationLink {
                    ScheduledPostsView(service: appViewModel.socialMediaService)
                } label: {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(colors.primary)
                        Text("Review Scheduled Posts")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }

            Section("Add to calendar") {
                DatePicker("Publish date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                Picker("Platform", selection: $viewModel.platform) {
                    ForEach(MarketingPlatform.allCases) { platform in
                        Text(platform.rawValue).tag(platform)
                    }
                }
                TextField("Title", text: $viewModel.title)
                TextField("Content", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(5...15)
                
                Toggle("Remind me to review and share", isOn: $viewModel.enableReminder)
                
                if viewModel.enableReminder {
                    Text("You'll receive a reminder at the scheduled time to review and share this post")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
                
                Button("Schedule item") {
                    if appViewModel.presentPaywallIfNeededForCalendar() { return }
                    Task {
                        guard let userId = appViewModel.userProfile?.userId else { return }
                        await viewModel.addItem(
                            userId: userId,
                            brandId: appViewModel.selectedBrand?.id,
                            currentCount: appViewModel.calendarItems.count,
                            tier: appViewModel.currentTier
                        )
                        await appViewModel.refreshPortal()
                    }
                }
            }

            if let message = viewModel.statusMessage {
                Section {
                    Text(message).foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private var itemsForSelectedDate: [ContentCalendarItem] {
        appViewModel.calendarItems.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: selectedCalendarDate)
        }
    }

    private func calendarListRow(_ item: ContentCalendarItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title).bold()
            Text(item.platform).font(.caption).foregroundColor(.secondary)
            Text(item.notes).font(.footnote).lineLimit(2)
        }
    }

    private func toggleSelection(_ id: String) {
        HapticFeedback.selection()
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    private var groupedEntries: [Date: [ContentCalendarItem]] {
        let items = filteredCalendarItems
        return Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.date)
        }
    }

    private var filteredCalendarItems: [ContentCalendarItem] {
        guard !searchText.isEmpty else { return appViewModel.calendarItems }
        return appViewModel.calendarItems.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            item.notes.localizedCaseInsensitiveContains(searchText) ||
            item.platform.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Supporting Views

struct CalendarItemRow: View {
    let item: ContentCalendarItem
    let onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    private var platformAccent: Color {
        HubPlatformColors.accent(for: item.platform, themePrimary: colors.primary)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                    Spacer()
                    HubPlatformChip(platform: item.platform, accent: platformAccent)
                }
                Text(item.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .hubPanelStyle(colors: colors)
        }
        .buttonStyle(.plain)
    }
}

struct CalendarItemDetailView: View {
    @State private var editedItem: ContentCalendarItem
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var statusMessage: String?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    private var platformAccent: Color {
        HubPlatformColors.accent(for: editedItem.platform, themePrimary: colors.primary)
    }

    private var linkedPost: ScheduledPost? {
        appViewModel.linkedScheduledPost(for: editedItem.id)
    }

    init(item: ContentCalendarItem) {
        _editedItem = State(initialValue: item)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isEditing {
                        editForm
                    } else {
                        viewMode
                    }
                }
                .padding()
            }
            .hubScreenBackground(colors)
            .navigationTitle(isEditing ? "Edit Item" : "Calendar Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            editedItem = item
                            isEditing = false
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            Task {
                                await saveChanges()
                            }
                        }
                        .disabled(isSaving || editedItem.title.isEmpty)
                    } else {
                        Button {
                            isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .alert("Delete Calendar Item", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteItem()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this calendar item? This action cannot be undone.")
            }
            .hubErrorAlert($errorMessage)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: ShareContentBuilder.shareItems(content: editedItem.notes))
            }
        }
    }
    
    private var item: ContentCalendarItem {
        editedItem
    }
    
    private var viewMode: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text(editedItem.title)
                    .font(.title2)
                    .bold()
                
                HStack {
                    HubPlatformChip(platform: editedItem.platform, accent: platformAccent)

                    if let post = linkedPost {
                        Text(post.status == .shared ? "Shared" : post.status.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: post.status).opacity(0.15), in: Capsule())
                            .foregroundColor(statusColor(for: post.status))
                    }

                    Text(editedItem.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Text("Content")
                .font(.headline)
            Text(editedItem.notes)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colors.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                NavigationLink {
                    ContentPreviewView(
                        content: editedItem.notes,
                        platform: MarketingPlatform(rawValue: editedItem.platform) ?? .instagram,
                        title: editedItem.title,
                        scheduledDate: editedItem.date
                    )
                } label: {
                    Label("Preview", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    UIPasteboard.general.string = editedItem.notes
                    HapticFeedback.success()
                    statusMessage = "Copied to clipboard"
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                showShareSheet = true
                HapticFeedback.light()
            } label: {
                Label("Share Now", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(colors.primary)
            .accessibilityHint("Opens the iOS Share Sheet to publish manually")

            if linkedPost?.status != .shared {
                Button {
                    Task {
                        await appViewModel.markPostShared(forCalendarItem: editedItem.id)
                        statusMessage = "Marked as shared"
                    }
                } label: {
                    Label("Mark as Shared", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func statusColor(for status: PostStatus) -> Color {
        switch status {
        case .shared, .posted: return .green
        case .readyForReview: return .orange
        case .scheduled: return colors.primary
        default: return .secondary
        }
    }
    
    private var editForm: some View {
        Group {
            Section {
                TextField("Title", text: Binding(
                    get: { editedItem.title },
                    set: { newTitle in
                        editedItem = ContentCalendarItem(
                            id: editedItem.id,
                            userId: editedItem.userId,
                            brandId: editedItem.brandId,
                            date: editedItem.date,
                            platform: editedItem.platform,
                            title: newTitle,
                            notes: editedItem.notes
                        )
                    }
                ))
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Title")
                    .font(.headline)
            }
            
            Section {
                Picker("Platform", selection: Binding(
                    get: { MarketingPlatform(rawValue: editedItem.platform) ?? .instagram },
                    set: { newPlatform in
                        editedItem = ContentCalendarItem(
                            id: editedItem.id,
                            userId: editedItem.userId,
                            brandId: editedItem.brandId,
                            date: editedItem.date,
                            platform: newPlatform.rawValue,
                            title: editedItem.title,
                            notes: editedItem.notes
                        )
                    }
                )) {
                    ForEach(MarketingPlatform.allCases) { platform in
                        Text(platform.rawValue).tag(platform)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Platform")
                    .font(.headline)
            }
            
            Section {
                DatePicker("Date & Time", selection: Binding(
                    get: { editedItem.date },
                    set: { newDate in
                        editedItem = ContentCalendarItem(
                            id: editedItem.id,
                            userId: editedItem.userId,
                            brandId: editedItem.brandId,
                            date: newDate,
                            platform: editedItem.platform,
                            title: editedItem.title,
                            notes: editedItem.notes
                        )
                    }
                ), displayedComponents: [.date, .hourAndMinute])
            } header: {
                Text("Schedule")
                    .font(.headline)
            }
            
            Section {
                TextEditor(text: Binding(
                    get: { editedItem.notes },
                    set: { newNotes in
                        editedItem = ContentCalendarItem(
                            id: editedItem.id,
                            userId: editedItem.userId,
                            brandId: editedItem.brandId,
                            date: editedItem.date,
                            platform: editedItem.platform,
                            title: editedItem.title,
                            notes: newNotes
                        )
                    }
                ))
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(colors.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } header: {
                Text("Content")
                    .font(.headline)
            }
            
            if isSaving {
                HStack {
                    Spacer()
                    ProgressView()
                    Text("Saving...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private func saveChanges() async {
        guard !appViewModel.isDemoMode else {
            errorMessage = HubMessages.demoReadOnly
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let saved = try await appViewModel.updateCalendarItemWithSync(editedItem)
            await MainActor.run {
                editedItem = saved
                isEditing = false
                HapticFeedback.success()
            }
        } catch {
            errorMessage = "Could not save this item. \(error.localizedDescription)"
            HapticFeedback.warning()
        }
    }

    private func deleteItem() async {
        guard !appViewModel.isDemoMode else {
            errorMessage = HubMessages.demoReadOnly
            return
        }

        do {
            try await appViewModel.deleteCalendarItemWithSync(editedItem)
            await MainActor.run {
                HapticFeedback.success()
                dismiss()
            }
        } catch {
            errorMessage = "Could not delete this item. \(error.localizedDescription)"
            HapticFeedback.warning()
        }
    }
}
