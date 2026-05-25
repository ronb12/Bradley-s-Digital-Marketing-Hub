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
            ZStack {
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
                        .disabled(subscriptionManager.isLoading)
                    }
                    .padding()
                }
                .hubScreenBackground(colors)

                if subscriptionManager.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Processing…")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { appViewModel.showPaywall = false }
                }
            }
            .onChange(of: subscriptionManager.currentTier) { _, tier in
                if tier != .free {
                    appViewModel.showPaywall = false
                }
            }
        }
    }

    private func planCard(tier: SubscriptionTier, features: [String], highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.displayName)
                        .font(.title3.bold())
                    if tier == .free {
                        Text("Free")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if let price = subscriptionManager.displayPrice(for: tier) {
                        Text("\(price) / month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Price loads from App Store")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
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
                Text(buttonTitle(for: tier))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(colors.primary)
            .disabled(isPlanDisabled(tier))
        }
        .hubCardStyle(colors: colors)
        .overlay {
            if highlighted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colors.primary.opacity(0.35), lineWidth: 2)
            }
        }
        .accessibilityIdentifier("paywall_plan_\(tier.rawValue)")
    }

    private func buttonTitle(for tier: SubscriptionTier) -> String {
        if tier == .free {
            return appViewModel.currentTier == .free ? "Current plan" : "Free tier"
        }
        if appViewModel.currentTier == tier {
            return "Current plan"
        }
        return "Choose \(tier.displayName)"
    }

    private func isPlanDisabled(_ tier: SubscriptionTier) -> Bool {
        if subscriptionManager.isLoading { return true }
        if tier == .free { return appViewModel.currentTier == .free }
        if appViewModel.currentTier == tier { return true }
        if tier != .free && subscriptionManager.displayPrice(for: tier) == nil && subscriptionManager.availableProducts.isEmpty {
            return false
        }
        return false
    }

    private func purchase(tier: SubscriptionTier) {
        guard tier != .free, appViewModel.currentTier != tier else { return }
        Task {
            await subscriptionManager.purchase(tier: tier)
            await appViewModel.updatePlan(to: subscriptionManager.currentTier)
        }
    }
}
