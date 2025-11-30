import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel = TemplatesViewModel()

    var body: some View {
        let visibleTemplates = viewModel.filteredTemplates(appViewModel.templates, tier: appViewModel.currentTier)

        return List {
            Section {
                TextField("Search templates", text: $viewModel.searchText)
            }
            Section {
                ForEach(visibleTemplates) { template in
                    Button {
                        if viewModel.isLocked(template, tier: appViewModel.currentTier) {
                            appViewModel.showPaywall = true
                        } else {
                            viewModel.selectedTemplate = template
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name).bold()
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if template.isAgencyOnly {
                                Text("Agency").font(.caption).padding(6)
                                    .background(Color.purple.opacity(0.2), in: Capsule())
                            } else if template.isPremium {
                                Text("Premium").font(.caption).padding(6)
                                    .background(Color.orange.opacity(0.2), in: Capsule())
                            }
                        }
                    }
                    .tint(.primary)
                }
            } header: {
                Text("Templates from CloudKit public database")
            } footer: {
                Text("Add Template records in CloudKit Dashboard. Placeholder PDFs can be attached via CKAsset.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Templates")
        .sheet(item: $viewModel.selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
    }
}

struct TemplateDetailView: View {
    let template: TemplateItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(template.name).font(.title2).bold()
            Text(template.description)
            Text("Preview Placeholder")
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.hubBackground, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    Text("Upload actual PDF in CloudKit and render with QuickLook later.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                )
            Spacer()
        }
        .padding()
    }
}
