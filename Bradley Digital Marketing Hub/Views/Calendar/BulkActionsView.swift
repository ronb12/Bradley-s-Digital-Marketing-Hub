import SwiftUI

struct BulkActionsView: View {
    @Binding var selectedItems: Set<String>
    let calendarItems: [ContentCalendarItem]
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var showMoveConfirmation = false
    @State private var selectedPlatform: MarketingPlatform = .instagram
    @State private var selectedDate: Date = Date()
    @State private var isProcessing = false
    
    var selectedItemsList: [ContentCalendarItem] {
        calendarItems.filter { selectedItems.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("\(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s") selected")
                        .font(.headline)
                }
                
                Section("Actions") {
                    Button {
                        showMoveConfirmation = true
                    } label: {
                        Label("Move to Date", systemImage: "calendar")
                    }
                    .disabled(selectedItems.isEmpty)
                    
                    Button {
                        showMoveConfirmation = true
                    } label: {
                        Label("Change Platform", systemImage: "app.badge")
                    }
                    .disabled(selectedItems.isEmpty)
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                    .disabled(selectedItems.isEmpty)
                }
                
                Section("Selected Items") {
                    ForEach(selectedItemsList) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(item.platform)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Bulk Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Items", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteSelected()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s")? This action cannot be undone.")
            }
            .sheet(isPresented: $showMoveConfirmation) {
                BulkActionOptionsView(
                    selectedItems: $selectedItems,
                    calendarItems: calendarItems,
                    onComplete: {
                        dismiss()
                    }
                )
                .environmentObject(appViewModel)
            }
        }
    }
    
    private func deleteSelected() async {
        guard !appViewModel.isDemoMode else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        for item in selectedItemsList {
            do {
                let recordID = CKRecord.ID(recordName: item.id)
                _ = try await appViewModel.cloudKitService.privateDB.deleteRecord(withID: recordID)
            } catch {
                print("Error deleting item \(item.id): \(error)")
            }
        }
        
        await MainActor.run {
            appViewModel.calendarItems.removeAll { selectedItems.contains($0.id) }
            selectedItems.removeAll()
            dismiss()
        }
    }
}

struct BulkActionOptionsView: View {
    @Binding var selectedItems: Set<String>
    let calendarItems: [ContentCalendarItem]
    let onComplete: () -> Void
    
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var actionType: BulkActionType = .changeDate
    @State private var selectedPlatform: MarketingPlatform = .instagram
    @State private var selectedDate: Date = Date()
    @State private var isProcessing = false
    
    enum BulkActionType {
        case changeDate
        case changePlatform
    }
    
    var selectedItemsList: [ContentCalendarItem] {
        calendarItems.filter { selectedItems.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Action", selection: $actionType) {
                    Text("Change Date").tag(BulkActionType.changeDate)
                    Text("Change Platform").tag(BulkActionType.changePlatform)
                }
                
                if actionType == .changeDate {
                    DatePicker("New Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                } else {
                    Picker("New Platform", selection: $selectedPlatform) {
                        ForEach(MarketingPlatform.allCases) { platform in
                            Text(platform.rawValue).tag(platform)
                        }
                    }
                }
                
                Button {
                    Task {
                        await applyBulkAction()
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Text("Apply to \(selectedItems.count) Item\(selectedItems.count == 1 ? "" : "s")")
                    }
                }
                .disabled(isProcessing || selectedItems.isEmpty)
            }
            .navigationTitle("Bulk Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyBulkAction() async {
        guard !appViewModel.isDemoMode else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        for item in selectedItemsList {
            var updatedItem = item
            
            if actionType == .changeDate {
                updatedItem = ContentCalendarItem(
                    id: item.id,
                    userId: item.userId,
                    brandId: item.brandId,
                    date: selectedDate,
                    platform: item.platform,
                    title: item.title,
                    notes: item.notes
                )
            } else {
                updatedItem = ContentCalendarItem(
                    id: item.id,
                    userId: item.userId,
                    brandId: item.brandId,
                    date: item.date,
                    platform: selectedPlatform.rawValue,
                    title: item.title,
                    notes: item.notes
                )
            }
            
            do {
                let saved = try await appViewModel.cloudKitService.saveCalendarItem(updatedItem)
                await MainActor.run {
                    if let index = appViewModel.calendarItems.firstIndex(where: { $0.id == saved.id }) {
                        appViewModel.calendarItems[index] = saved
                    }
                }
            } catch {
                print("Error updating item \(item.id): \(error)")
            }
        }
        
        await MainActor.run {
            selectedItems.removeAll()
            dismiss()
            onComplete()
        }
    }
}

