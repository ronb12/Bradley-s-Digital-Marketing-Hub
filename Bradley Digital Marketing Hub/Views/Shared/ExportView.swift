import SwiftUI

struct ExportView: View {
    let calendarItems: [ContentCalendarItem]
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var exportFormat: ExportFormat = .csv
    @State private var dateRange: DateRange = .all
    @State private var selectedPlatform: MarketingPlatform? = nil
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case plainText = "Plain Text"
    }
    
    enum DateRange: String, CaseIterable {
        case all = "All Items"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last30Days = "Last 30 Days"
    }
    
    var filteredItems: [ContentCalendarItem] {
        var items = calendarItems
        
        // Filter by platform
        if let platform = selectedPlatform {
            items = items.filter { $0.platform.lowercased() == platform.rawValue.lowercased() }
        }
        
        // Filter by date range
        items = filterByDateRange(items)
        
        return items.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Options") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    
                    Picker("Platform", selection: $selectedPlatform) {
                        Text("All Platforms").tag(nil as MarketingPlatform?)
                        ForEach(MarketingPlatform.allCases) { platform in
                            Text(platform.rawValue).tag(platform as MarketingPlatform?)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Items to Export")
                        Spacer()
                        Text("\(filteredItems.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Summary")
                }
                
                Section {
                    Button {
                        Task {
                            await export()
                        }
                    } label: {
                        if isExporting {
                            HStack {
                                ProgressView()
                                Text("Exporting...")
                            }
                        } else {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Calendar Items")
                            }
                        }
                    }
                    .disabled(isExporting || filteredItems.isEmpty)
                }
                
                if !filteredItems.isEmpty {
                    Section("Preview") {
                        ForEach(filteredItems.prefix(5)) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(item.platform) • \(item.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if filteredItems.count > 5 {
                            Text("... and \(filteredItems.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .hubScreenBackground(colors)
            .navigationTitle("Export Calendar")
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .hubErrorAlert($errorMessage, title: "Export Failed")
        }
    }
    
    private func filterByDateRange(_ items: [ContentCalendarItem]) -> [ContentCalendarItem] {
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .all:
            return items
        case .thisWeek:
            return items.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .thisMonth:
            return items.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .last30Days:
            if let startDate = calendar.date(byAdding: .day, value: -30, to: now) {
                return items.filter { $0.date >= startDate }
            }
            return items
        }
    }
    
    private func export() async {
        guard !filteredItems.isEmpty else { return }
        
        isExporting = true
        defer { isExporting = false }
        
        let url: URL?
        
        switch exportFormat {
        case .csv:
            url = await exportToCSV()
        case .json:
            url = await exportToJSON()
        case .plainText:
            url = await exportToPlainText()
        }
        
        await MainActor.run {
            exportURL = url
            if let url {
                showShareSheet = true
                HapticFeedback.success()
            } else {
                errorMessage = "Could not create the export file. Please try again."
                HapticFeedback.warning()
            }
        }
    }

    private enum ExportWriteError: LocalizedError {
        case writeFailed(String)

        var errorDescription: String? {
            switch self {
            case .writeFailed(let detail): return detail
            }
        }
    }

    private func writeExport(data: Data, to fileURL: URL) throws {
        do {
            try data.write(to: fileURL)
        } catch {
            throw ExportWriteError.writeFailed(error.localizedDescription)
        }
    }

    private func writeExport(text: String, to fileURL: URL) throws {
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw ExportWriteError.writeFailed(error.localizedDescription)
        }
    }
    
    private func exportToCSV() async -> URL? {
        let fileName = "calendar_export_\(Date().timeIntervalSince1970).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvContent = "Date,Time,Platform,Title,Content\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for item in filteredItems {
            let dateString = dateFormatter.string(from: item.date)
            let timeString = timeFormatter.string(from: item.date)
            let title = escapeCSV(item.title)
            let content = escapeCSV(item.notes)

            csvContent += "\(dateString),\(timeString),\(item.platform),\(title),\(content)\n"
        }

        do {
            try writeExport(text: csvContent, to: fileURL)
            return fileURL
        } catch {
            await MainActor.run {
                errorMessage = "CSV export failed. \(error.localizedDescription)"
            }
            return nil
        }
    }

    private func exportToJSON() async -> URL? {
        let fileName = "calendar_export_\(Date().timeIntervalSince1970).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let dateFormatter = ISO8601DateFormatter()

        let jsonItems = filteredItems.map { item in
            [
                "id": item.id,
                "title": item.title,
                "platform": item.platform,
                "date": dateFormatter.string(from: item.date),
                "content": item.notes,
                "brandId": item.brandId ?? ""
            ]
        }

        let jsonData: [String: Any] = [
            "exportDate": dateFormatter.string(from: Date()),
            "totalItems": filteredItems.count,
            "items": jsonItems
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
            try writeExport(data: data, to: fileURL)
            return fileURL
        } catch {
            await MainActor.run {
                errorMessage = "JSON export failed. \(error.localizedDescription)"
            }
            return nil
        }
    }

    private func exportToPlainText() async -> URL? {
        let fileName = "calendar_export_\(Date().timeIntervalSince1970).txt"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var text = "Bradley Digital Marketing Hub — Calendar Export\n"
        text += "Exported: \(Date().formatted())\n"
        text += "Items: \(filteredItems.count)\n\n"

        for item in filteredItems {
            text += "---\n"
            text += "Title: \(item.title)\n"
            text += "Platform: \(item.platform)\n"
            text += "Date: \(item.date.formatted(date: .complete, time: .shortened))\n"
            text += "Content:\n\(item.notes)\n\n"
        }

        do {
            try writeExport(text: text, to: fileURL)
            return fileURL
        } catch {
            await MainActor.run {
                errorMessage = "Plain text export failed. \(error.localizedDescription)"
            }
            return nil
        }
    }

    private func escapeCSV(_ text: String) -> String {
        // Escape quotes and wrap in quotes if contains comma or quote
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return text
    }
}

