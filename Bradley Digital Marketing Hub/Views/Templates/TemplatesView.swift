import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = TemplatesViewModel()

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        let visibleTemplates = viewModel.filteredTemplates(appViewModel.templates, tier: appViewModel.currentTier)

        Group {
            if visibleTemplates.isEmpty && viewModel.searchText.isEmpty {
                HubEmptyState(
                    icon: "doc.richtext",
                    title: "No templates yet",
                    message: "Templates appear here once published. Tap + to add your own."
                )
                .padding()
            } else {
                List {
                    Section {
                        SearchView(searchText: $viewModel.searchText, placeholder: "Search templates", surfaceColor: colors.surface)
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
                        Text("Marketing Templates")
                    } footer: {
                        Text("Browse ready-to-use assets for your campaigns.")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .hubScreenBackground(colors)
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SaveTemplateView()
                } label: {
                    Label("Add Template", systemImage: "plus")
                }
            }
        }
        .sheet(item: $viewModel.selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
    }
}

struct TemplateDetailView: View {
    let template: TemplateItem
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(template.name).font(.title2).bold()
                Text(template.description)
                VStack(spacing: 12) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 48))
                        .foregroundColor(colors.primary.opacity(0.6))
                    Text("Template preview")
                        .font(.headline)
                    Text("Open this template to copy content into your calendar or generator.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(colors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .hubScreenBackground(colors)
    }
}
