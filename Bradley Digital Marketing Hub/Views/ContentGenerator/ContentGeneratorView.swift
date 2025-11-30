import SwiftUI

struct ContentGeneratorView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: ContentGeneratorViewModel

    init(service: CloudKitService) {
        _viewModel = StateObject(wrappedValue: ContentGeneratorViewModel(service: service))
    }

    var body: some View {
        Form {
            Section(header: Text("Inputs")) {
                TextField("Business type", text: $viewModel.businessType)
                TextField("Audience", text: $viewModel.audience)
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
                Button("Generate Content") {
                    viewModel.generate()
                }
                .buttonStyle(.borderedProminent)
            }

            if !viewModel.generatedContent.isEmpty {
                Section(header: Text("Ideas")) {
                    ForEach(Array(viewModel.generatedContent.enumerated()), id: \\.offset) { index, idea in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Idea #\(index + 1)").font(.headline)
                            Text(idea)
                            Button {
                                Task {
                                    if let userId = appViewModel.userProfile?.userId {
                                        await viewModel.saveToCalendar(text: idea, userId: userId, brandId: appViewModel.selectedBrand?.id)
                                    }
                                }
                            } label: {
                                Label("Save to calendar", systemImage: "tray.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
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
