import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.largeTitle)
                            .foregroundStyle(colors.primary)
                        Text("Unlock more marketing firepower")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text("Choose the plan that fits your workflow")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 14) {
                        planCard(tier: .free, features: [
                            "3 campaign plans",
                            "10 calendar items",
                            "Core templates",
                            "Affiliate list",
                            "Booking access"
                        ])
                        planCard(tier: .pro, features: [
                            "Unlimited plans",
                            "Unlimited calendar",
                            "Premium templates",
                            "Pro affiliate picks",
                            "Priority booking"
                        ], highlighted: true)
                        planCard(tier: .agency, features: [
                            "10 brands",
                            "Agency-only templates",
                            "Brand switching",
                            "Campaign exports",
                            "Team-ready workflows"
                        ])
                    }

                    if let message = subscriptionManager.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button("Restore Purchases") {
                        Task { await subscriptionManager.restorePurchases() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .hubScreenBackground(colors)
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { appViewModel.showPaywall = false }
                }
            }
        }
    }

    private func planCard(tier: SubscriptionTier, features: [String], highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(tier.displayName)
                    .font(.title3.bold())
                Spacer()
                if highlighted {
                    Text("Popular")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colors.primary.opacity(0.15), in: Capsule())
                        .foregroundColor(colors.primary)
                }
            }

            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Button(action: { purchase(tier: tier) }) {
                Text(tier == .free ? "Current plan" : "Choose \(tier.displayName)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(colors.primary)
            .disabled(tier == .free && appViewModel.currentTier == .free)

            if tier != .free {
                Text(tier.productIdentifier ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .hubCardStyle(colors: colors)
        .overlay {
            if highlighted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colors.primary.opacity(0.35), lineWidth: 2)
            }
        }
    }

    private func purchase(tier: SubscriptionTier) {
        guard tier != .free else { return }
        Task {
            await subscriptionManager.purchase(tier: tier)
            await appViewModel.updatePlan(to: subscriptionManager.currentTier)
        }
    }
}
