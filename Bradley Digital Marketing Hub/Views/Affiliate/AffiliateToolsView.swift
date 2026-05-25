import SwiftUI

struct AffiliateToolsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = AffiliateToolsViewModel()
    @State private var selectedURL: URL?

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        Group {
            if appViewModel.affiliateTools.isEmpty {
                HubEmptyState(
                    icon: "link",
                    title: "No affiliate tools",
                    message: "Recommended tools will appear here as they're added."
                )
                .padding()
            } else {
                List {
                    ForEach(appViewModel.affiliateTools) { tool in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(tool.name).bold()
                                if let badge = viewModel.badgeText(for: tool, tier: appViewModel.currentTier) {
                                    Text(badge)
                                        .font(.caption)
                                        .padding(4)
                                        .background(colors.accent.opacity(0.2), in: Capsule())
                                }
                            }
                            Text(tool.shortDescription).font(.caption)
                            Button("View Tool") {
                                if let url = URL(string: tool.url) {
                                    selectedURL = url
                                    Task { await appViewModel.logAffiliateClick(tool: tool) }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 6)
                    }
                    Section(footer: Text("Affiliate links open in Safari. Clicks help us recommend better tools.")) { EmptyView() }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .hubScreenBackground(colors)
        .navigationTitle("Affiliate Tools")
        .sheet(isPresented: Binding(
            get: { selectedURL != nil },
            set: { isPresented in
                if !isPresented { selectedURL = nil }
            })
        ) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }
    }
}
