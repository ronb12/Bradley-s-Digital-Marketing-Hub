import SwiftUI

struct CampaignPlannerView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: CampaignPlannerViewModel

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
        .navigationTitle("Campaign Planner")
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Platform", selection: $viewModel.platform) {
                ForEach(MarketingPlatform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            TextField("Goal (traffic, sales, awareness)", text: $viewModel.goal)
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
        .primarySectionStyle()
    }

    private var outlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outline").font(.headline)
            Text(viewModel.outline.isEmpty ? "Tap generate to draft an outline." : viewModel.outline)
                .font(.body)
        }
        .primarySectionStyle()
    }

    private var recommendedTools: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Tools").font(.headline)
            if appViewModel.affiliateTools.isEmpty {
                Text("Add AffiliateTool records in the public database to surface them here.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(appViewModel.affiliateTools.prefix(3)) { tool in
                    VStack(alignment: .leading) {
                        Text(tool.name).bold()
                        Text(tool.shortDescription).font(.caption)
                    }
                    .padding()
                    .background(Color.hubBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .primarySectionStyle()
    }
}
