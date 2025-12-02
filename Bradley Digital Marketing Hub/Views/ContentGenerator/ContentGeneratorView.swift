import SwiftUI

struct ContentGeneratorView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: ContentGeneratorViewModel

    init(service: CloudKitService) {
        _viewModel = StateObject(wrappedValue: ContentGeneratorViewModel(service: service))
    }

    var body: some View {
        Form {
            Section(header: Text("Content Settings")) {
                // Business Type Picker
                Picker("Business Type", selection: $viewModel.businessTypeOption) {
                    ForEach(BusinessType.allWithCustom) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                
                // Custom Business Type TextField (shown only when custom is selected)
                if case .custom = viewModel.businessTypeOption {
                    TextField("Enter business type", text: $viewModel.customBusinessType)
                        .autocapitalization(.words)
                }
                
                // Audience Picker
                Picker("Target Audience", selection: $viewModel.audienceOption) {
                    ForEach(TargetAudience.allWithCustom) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                
                // Custom Audience TextField (shown only when custom is selected)
                if case .custom = viewModel.audienceOption {
                    TextField("Enter target audience", text: $viewModel.customAudience)
                        .autocapitalization(.words)
                }
                
                // Tone Picker
                Picker("Tone", selection: $viewModel.tone) {
                    ForEach(MarketingTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                
                // Platform Picker
                Picker("Platform", selection: $viewModel.platform) {
                    ForEach(MarketingPlatform.allCases) { platform in
                        Text(platform.rawValue).tag(platform)
                    }
                }
            }
            
            Section {
                Button {
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

            if !viewModel.generatedContent.isEmpty {
                Section(header: Text("Generated Content")) {
                    ForEach($viewModel.generatedContent.indices, id: \.self) { index in
                        GeneratedContentCard(
                            item: $viewModel.generatedContent[index],
                            index: index,
                            onContentUpdate: { newContent in
                                viewModel.updateContent(at: viewModel.generatedContent[index].id, to: newContent)
                            },
                            onCopy: {
                                UIPasteboard.general.string = viewModel.generatedContent[index].content
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
            
            if let copyMessage = viewModel.copyStatusMessage {
                Section {
                    Text(copyMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            if let message = viewModel.statusMessage {
                Section {
                    Text(message).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Content Generator")
    }
}

