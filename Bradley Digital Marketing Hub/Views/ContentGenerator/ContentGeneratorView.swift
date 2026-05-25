import SwiftUI

struct ContentGeneratorView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ContentGeneratorViewModel
    @State private var scheduleItem: ContentGeneratorViewModel.GeneratedContentItem?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    init(service: CloudKitService) {
        _viewModel = StateObject(wrappedValue: ContentGeneratorViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                settingsSection
                generateButtonSection

                if !viewModel.generatedContent.isEmpty {
                    generatedSection
                }

                if let copyMessage = viewModel.copyStatusMessage {
                    Text(copyMessage)
                        .foregroundColor(colors.accent)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let message = viewModel.statusMessage {
                    Text(message)
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .hubScreenBackground(colors)
        .navigationTitle("Content Generator")
        .sheet(item: $scheduleItem) { item in
            SchedulePostSheet(
                platform: item.platform,
                content: item.content,
                defaultTitle: "Generated \(item.platform.rawValue) Post"
            ) { title, date, enableReminder, mediaURLs in
                do {
                    try await appViewModel.scheduleContent(
                        title: title,
                        content: item.content,
                        platform: item.platform,
                        date: date,
                        enableReminder: enableReminder,
                        mediaURLs: mediaURLs
                    )
                    viewModel.statusMessage = "Scheduled with reminder — check Home when it's time to share."
                } catch {
                    appViewModel.errorMessage = error.localizedDescription
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    SearchableSavedContent()
                } label: {
                    Label("Saved", systemImage: "heart.text.square")
                }
                NavigationLink {
                    HashtagResearchView()
                } label: {
                    Label("Hashtags", systemImage: "number")
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader("Content Settings", subtitle: "Tailor output to your audience and platform")

            Picker("Business Type", selection: $viewModel.businessTypeOption) {
                ForEach(BusinessType.allWithCustom) { option in
                    Text(option.displayName).tag(option)
                }
            }

            if case .custom = viewModel.businessTypeOption {
                TextField("Enter business type", text: $viewModel.customBusinessType)
                    .autocapitalization(.words)
            }

            Picker("Target Audience", selection: $viewModel.audienceOption) {
                ForEach(TargetAudience.allWithCustom) { option in
                    Text(option.displayName).tag(option)
                }
            }

            if case .custom = viewModel.audienceOption {
                TextField("Enter target audience", text: $viewModel.customAudience)
                    .autocapitalization(.words)
            }

            Picker("Tone", selection: $viewModel.tone) {
                ForEach(MarketingTone.allCases) { tone in
                    Text(tone.rawValue).tag(tone)
                }
            }

            Picker("Platform", selection: $viewModel.platform) {
                ForEach(MarketingPlatform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
        }
        .hubCardStyle(colors: colors)
    }

    private var generateButtonSection: some View {
        VStack(spacing: 8) {
            if let remaining = viewModel.remainingGenerations(tier: appViewModel.currentTier) {
                Text("\(remaining) free generations left today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                if !viewModel.canGenerate(tier: appViewModel.currentTier) {
                    appViewModel.showPaywall = true
                    return
                }
                HapticFeedback.light()
                viewModel.generate()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Generate Content")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var generatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader("Generated Content")

            ForEach($viewModel.generatedContent.indices, id: \.self) { index in
                GeneratedContentCard(
                    item: $viewModel.generatedContent[index],
                    index: index,
                    onContentUpdate: { newContent in
                        viewModel.updateContent(at: viewModel.generatedContent[index].id, to: newContent)
                    },
                    onCopy: {
                        UIPasteboard.general.string = viewModel.generatedContent[index].content
                        HapticFeedback.success()
                        viewModel.copyStatusMessage = "Copied to clipboard!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.copyStatusMessage = nil
                        }
                    },
                    onSave: {
                        Task {
                            if let userId = appViewModel.userProfile?.userId {
                                await viewModel.saveToCalendar(
                                    text: viewModel.generatedContent[index].content,
                                    userId: userId,
                                    brandId: appViewModel.selectedBrand?.id
                                )
                            }
                        }
                    },
                    onSchedule: {
                        scheduleItem = viewModel.generatedContent[index]
                    },
                    onFavorite: {
                        Task {
                            if let userId = appViewModel.userProfile?.userId {
                                await viewModel.saveAsFavorite(
                                    content: viewModel.generatedContent[index].content,
                                    userId: userId,
                                    platform: viewModel.generatedContent[index].platform
                                )
                            }
                        }
                    },
                    onRegenerate: {
                        viewModel.regenerateItem(at: index)
                    }
                )
            }
        }
    }
}
