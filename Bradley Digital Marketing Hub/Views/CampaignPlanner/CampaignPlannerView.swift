import SwiftUI

struct CampaignPlannerView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: CampaignPlannerViewModel

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    init(service: CloudKitService) {
        _viewModel = StateObject(wrappedValue: CampaignPlannerViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formSection
                outlineSection
                recommendedTools
            }
            .padding()
        }
        .hubScreenBackground(colors)
        .navigationTitle("Campaign Planner")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CampaignPlansListView()
                } label: {
                    Label("Saved Plans", systemImage: "folder")
                }
            }
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader("Campaign Settings", subtitle: "Configure your campaign parameters")

            Picker("Platform", selection: $viewModel.platform) {
                ForEach(MarketingPlatform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            Picker("Campaign Goal", selection: $viewModel.goalOption) {
                ForEach(CampaignGoal.allWithCustom) { option in
                    Text(option.displayName).tag(option)
                }
            }

            if case .custom = viewModel.goalOption {
                TextField("Enter campaign goal", text: $viewModel.customGoal)
                    .autocapitalization(.words)
            }
            Slider(value: $viewModel.budget, in: 100...10000, step: 100) {
                Text("Budget")
            } minimumValueLabel: {
                Text("$100")
            } maximumValueLabel: {
                Text("$10k")
            }
            Text("Budget: $\(Int(viewModel.budget))")
            if appViewModel.currentTier == .agency {
                Picker("Brand", selection: Binding<String?>(
                    get: { viewModel.selectedBrand?.id ?? appViewModel.selectedBrand?.id },
                    set: { newValue in
                        viewModel.selectedBrand = appViewModel.brands.first(where: { $0.id == newValue })
                    })
                ) {
                    ForEach(appViewModel.brands) { brand in
                        Text(brand.name).tag(brand.id as String?)
                    }
                }
            }
            Button("Generate outline") {
                viewModel.generateOutline()
            }
            .buttonStyle(.borderedProminent)
            Button("Save plan") {
                if appViewModel.presentPaywallIfNeededForCampaign() { return }
                Task {
                    guard let userId = appViewModel.userProfile?.userId else { return }
                    await viewModel.savePlan(
                        userId: userId,
                        brandId: viewModel.selectedBrand?.id ?? appViewModel.selectedBrand?.id,
                        currentCount: appViewModel.campaignPlans.count,
                        tier: appViewModel.currentTier
                    )
                    await appViewModel.refreshPortal()
                }
            }
            .buttonStyle(.bordered)
        }
        .hubCardStyle(colors: colors)
    }

    private var outlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader("Outline")
            Text(viewModel.outline.isEmpty ? "Tap generate to draft an outline." : viewModel.outline)
                .font(.body)
        }
        .hubCardStyle(colors: colors)
    }

    private var recommendedTools: some View {
        VStack(alignment: .leading, spacing: 8) {
            HubSectionHeader("Recommended Tools")
            if appViewModel.affiliateTools.isEmpty {
                HubEmptyState(
                    icon: "link",
                    title: "No tools yet",
                    message: "Add AffiliateTool records in the public database to surface them here."
                )
            } else {
                ForEach(appViewModel.affiliateTools.prefix(3)) { tool in
                    VStack(alignment: .leading) {
                        Text(tool.name).bold()
                        Text(tool.shortDescription).font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .hubCardStyle(colors: colors)
    }
}
