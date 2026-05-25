import SwiftUI

struct HelpCenterView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HubSectionHeader("How Bradley Hub works", subtitle: "Your manual-share scheduling workflow")

                faqItem(
                    question: "Why manual sharing?",
                    answer: "Platform APIs require OAuth approval and ongoing maintenance. Manual sharing through the iOS Share Sheet is reliable today — you stay in control of every post."
                )
                faqItem(
                    question: "How do I post to Instagram or TikTok?",
                    answer: "When a reminder arrives, tap Review → Share. For Instagram and TikTok, choose the app from the Share Sheet, then paste your caption if needed."
                )
                faqItem(
                    question: "What does Mark as Shared do?",
                    answer: "It updates your queue so you know what's published. Planning Analytics uses this to show your consistency — not platform engagement."
                )
                faqItem(
                    question: "What's the difference between calendar items and scheduled posts?",
                    answer: "Calendar items are your content plan. Scheduled posts with reminders trigger notifications when it's time to share."
                )

                HubSectionHeader("Support")

                Link(destination: URL(string: "mailto:\(AppConstants.marketingSupportEmail)?subject=Bradley%20Hub%20Support")!) {
                    Label("Email support", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)

                NavigationLink {
                    SocialAccountsView(service: appViewModel.socialMediaService)
                } label: {
                    Label("Manual share setup guide", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .hubScreenBackground(colors)
        .navigationTitle("Help Center")
    }

    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline.bold())
            Text(answer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .hubPanelStyle(colors: colors)
    }
}

import SwiftUI
import PhotosUI

struct SchedulePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let platform: MarketingPlatform
    let content: String
    let defaultTitle: String
    let onSchedule: (String, Date, Bool, [String]) async -> Void

    @State private var title: String
    @State private var scheduledDate = Date().addingTimeInterval(3600)
    @State private var enableReminder = true
    @State private var isScheduling = false
    @State private var photoItem: PhotosPickerItem?
    @State private var attachedImagePath: String?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    init(
        platform: MarketingPlatform,
        content: String,
        defaultTitle: String = "Scheduled Post",
        onSchedule: @escaping (String, Date, Bool, [String]) async -> Void
    ) {
        self.platform = platform
        self.content = content
        self.defaultTitle = defaultTitle
        self.onSchedule = onSchedule
        _title = State(initialValue: defaultTitle)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Post") {
                    TextField("Title", text: $title)
                    Text(platform.rawValue)
                        .foregroundColor(.secondary)
                    Text(content)
                        .font(.caption)
                        .lineLimit(6)
                }

                Section("Media (optional)") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(attachedImagePath == nil ? "Attach photo" : "Photo attached", systemImage: "photo")
                    }
                    if attachedImagePath != nil {
                        Button("Remove photo", role: .destructive) {
                            attachedImagePath = nil
                            photoItem = nil
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Publish date", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Remind me to review and share", isOn: $enableReminder)
                    Text("Manual share works best with reminders enabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .hubScreenBackground(colors)
            .navigationTitle("Schedule Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        Task {
                            isScheduling = true
                            let media = attachedImagePath.map { [$0] } ?? []
                            await onSchedule(title, scheduledDate, enableReminder, media)
                            isScheduling = false
                            dismiss()
                        }
                    }
                    .disabled(isScheduling || title.isEmpty)
                }
            }
            .onChange(of: photoItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        let url = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("jpg")
                        try? data.write(to: url)
                        attachedImagePath = url.path
                    }
                }
            }
        }
    }
}
