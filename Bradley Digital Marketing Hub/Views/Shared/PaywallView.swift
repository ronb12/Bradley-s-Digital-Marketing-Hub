import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Unlock more marketing firepower")
                        .font(.title2).bold()
                        .multilineTextAlignment(.center)
                    comparisonColumns
                    if let message = subscriptionManager.errorMessage {
                        Text(message).foregroundColor(.red)
                    }
                    Button("Restore Purchases") {
                        Task { await subscriptionManager.restorePurchases() }
                    }
                }
                .padding()
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { appViewModel.showPaywall = false }
                }
            }
        }
    }

    private var comparisonColumns: some View {
        HStack(alignment: .top, spacing: 12) {
            planColumn(tier: .free, features: [
                "3 campaign plans",
                "10 calendar items",
                "Core templates",
                "Affiliate list",
                "Booking access"
            ])
            planColumn(tier: .pro, features: [
                "Unlimited plans",
                "Unlimited calendar",
                "Premium templates",
                "Pro affiliate picks",
                "Priority booking"
            ])
            planColumn(tier: .agency, features: [
                "10 brands",
                "Agency-only templates",
                "Brand switching",
                "Campaign exports",
                "Team-ready"
            ])
        }
    }

    private func planColumn(tier: SubscriptionTier, features: [String]) -> some View {
        VStack(spacing: 8) {
            Text(tier.displayName).font(.headline)
            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.seal")
                    .font(.caption)
                    .labelStyle(.titleAndIcon)
            }
            Button(action: { purchase(tier: tier) }) {
                Text(tier == .free ? "Current" : "Choose \(tier.displayName)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Text(tier.productIdentifier ?? "Included")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.hubBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private func purchase(tier: SubscriptionTier) {
        guard tier != .free else { return }
        Task {
            await subscriptionManager.purchase(tier: tier)
            await appViewModel.updatePlan(to: subscriptionManager.currentTier)
        }
    }
}
