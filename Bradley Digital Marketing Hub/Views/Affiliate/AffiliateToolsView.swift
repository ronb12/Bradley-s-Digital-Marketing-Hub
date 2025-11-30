import SwiftUI

struct AffiliateToolsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel = AffiliateToolsViewModel()
    @State private var selectedURL: URL?

    var body: some View {
        List {
            ForEach(appViewModel.affiliateTools) { tool in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(tool.name).bold()
                        if let badge = viewModel.badgeText(for: tool, tier: appViewModel.currentTier) {
                            Text(badge)
                                .font(.caption)
                                .padding(4)
                                .background(Color.orange.opacity(0.2), in: Capsule())
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
            Section(footer: Text("Affiliate clicks are logged via AffiliateClick records.")) { EmptyView() }
        }
        .listStyle(.insetGrouped)
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
