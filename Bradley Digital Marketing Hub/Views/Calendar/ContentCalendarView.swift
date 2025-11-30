import SwiftUI

struct ContentCalendarView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: ContentCalendarViewModel

    init(service: CloudKitService? = nil) {
        _viewModel = StateObject(wrappedValue: ContentCalendarViewModel(service: service ?? CloudKitService()))
    }

    var body: some View {
        List {
            ForEach(groupedEntries.keys.sorted(), id: \\.self) { date in
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

            Section("Add to calendar") {
                DatePicker("Publish date", selection: $viewModel.date, displayedComponents: [.date])
                Picker("Platform", selection: $viewModel.platform) {
                    ForEach(MarketingPlatform.allCases) { platform in
                        Text(platform.rawValue).tag(platform)
                    }
                }
                TextField("Title", text: $viewModel.title)
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
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
        .navigationTitle("Content Calendar")
    }

    private var groupedEntries: [Date: [ContentCalendarItem]] {
        Dictionary(grouping: appViewModel.calendarItems) { item in
            Calendar.current.startOfDay(for: item.date)
        }
    }
}
