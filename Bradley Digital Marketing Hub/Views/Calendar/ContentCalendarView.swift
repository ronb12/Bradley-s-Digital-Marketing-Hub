import SwiftUI

enum CalendarViewMode {
    case list
    case calendar
}

struct ContentCalendarView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: ContentCalendarViewModel
    @State private var viewMode: CalendarViewMode = .list
    @State private var selectedCalendarDate: Date = Date()
    @State private var selectedItem: ContentCalendarItem?
    @State private var showItemDetail = false

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
        .navigationTitle("Content Calendar")
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
            ForEach(groupedEntries.keys.sorted(), id: \.self) { date in
                Section(header: Text(DateFormatter.shortDate.string(from: date))) {
                    ForEach(groupedEntries[date] ?? []) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).bold()
                            Text(item.platform).font(.caption).foregroundColor(.secondary)
                            Text(item.notes).font(.footnote)
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
                            .foregroundColor(.blue)
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
    }
    
    private var itemsForSelectedDate: [ContentCalendarItem] {
        appViewModel.calendarItems.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: selectedCalendarDate)
        }
    }

    private var groupedEntries: [Date: [ContentCalendarItem]] {
        Dictionary(grouping: appViewModel.calendarItems) { item in
            Calendar.current.startOfDay(for: item.date)
        }
    }
}

// MARK: - Supporting Views

struct CalendarItemRow: View {
    let item: ContentCalendarItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                    Spacer()
                    Text(item.platform)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
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
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct CalendarItemDetailView: View {
    @State private var editedItem: ContentCalendarItem
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    
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
                    Text(editedItem.platform)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
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
                .background(Color(.systemGray6))
                .cornerRadius(10)
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
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let saved = try await appViewModel.cloudKitService.saveCalendarItem(editedItem)
            // Update the item in the app's calendar items array
            await MainActor.run {
                if let index = appViewModel.calendarItems.firstIndex(where: { $0.id == saved.id }) {
                    appViewModel.calendarItems[index] = saved
                } else {
                    // Item might have been new, add it
                    appViewModel.calendarItems.append(saved)
                }
                editedItem = saved
                isEditing = false
            }
        } catch {
            // Handle error - could show alert
            print("Error saving calendar item: \(error)")
        }
    }
    
    private func deleteItem() async {
        guard !appViewModel.isDemoMode else {
            return
        }
        
        do {
            // Delete from CloudKit
            let recordID = CKRecord.ID(recordName: editedItem.id)
            _ = try await appViewModel.cloudKitService.privateDB.deleteRecord(withID: recordID)
            
            // Remove from local array
            await MainActor.run {
                if let index = appViewModel.calendarItems.firstIndex(where: { $0.id == editedItem.id }) {
                    appViewModel.calendarItems.remove(at: index)
                }
                dismiss()
            }
        } catch {
            print("Error deleting calendar item: \(error)")
        }
    }
}
