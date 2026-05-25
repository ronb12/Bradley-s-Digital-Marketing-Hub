import SwiftUI

struct SocialAccountsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: SocialAccountsViewModel

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    init(service: SocialMediaService) {
        _viewModel = StateObject(wrappedValue: SocialAccountsViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HubSectionHeader(
                    "Manual Share Workflow",
                    subtitle: "Bradley Hub schedules reminders — you publish through each platform's app using the iOS Share Sheet."
                )

                VStack(alignment: .leading, spacing: 12) {
                    workflowStep(number: 1, title: "Schedule a post", detail: "Add content to your calendar or scheduled posts queue.")
                    workflowStep(number: 2, title: "Get reminded", detail: "When it's time, you'll receive a notification to review the post.")
                    workflowStep(number: 3, title: "Share manually", detail: "Tap Share to open the iOS Share Sheet and pick Instagram, Facebook, X, or any installed app.")
                    workflowStep(number: 4, title: "Mark as shared", detail: "Confirm once you've published so your queue stays accurate.")
                }
                .hubCardStyle(colors: colors)

                NavigationLink {
                    ScheduledPostsView(service: appViewModel.socialMediaService)
                } label: {
                    Label("View Scheduled Posts", systemImage: "clock.badge.checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(colors.primary)

                HubDataDisclaimer(
                    title: "Direct API posting coming later",
                    message: "Automatic publishing through platform APIs requires OAuth setup per network. Until then, sharing is manual and transparent — no mock connections or fake auto-posts."
                )

                if !viewModel.legacyAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HubSectionHeader("Legacy Placeholder Accounts", subtitle: "These were created by an older demo flow and can be removed.")

                        ForEach(viewModel.legacyAccounts) { account in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(account.accountName)
                                        .font(.subheadline.bold())
                                    Text(account.platform)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Remove") {
                                    Task { await viewModel.removeLegacyAccount(account) }
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .hubCardStyle(colors: colors)
                }
            }
            .padding()
        }
        .hubScreenBackground(colors)
        .navigationTitle("Share Setup")
        .task {
            if let userId = appViewModel.userProfile?.userId {
                viewModel.setUserId(userId)
            }
            await viewModel.loadAccounts()
        }
    }

    private func workflowStep(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(colors.primary.opacity(0.15), in: Circle())
                .foregroundColor(colors.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@MainActor
final class SocialAccountsViewModel: ObservableObject {
    @Published var legacyAccounts: [ConnectedSocialAccount] = []

    private let service: SocialMediaService
    private var userId: String?

    init(service: SocialMediaService) {
        self.service = service
    }

    func setUserId(_ userId: String) {
        self.userId = userId
    }

    func loadAccounts() async {
        guard let userId else { return }
        do {
            let accounts = try await service.fetchConnectedAccounts(userId: userId)
            legacyAccounts = accounts.filter {
                ($0.accessToken?.hasPrefix("mock_") == true) || $0.accountName.hasPrefix("Mock ")
            }
        } catch {
            legacyAccounts = []
        }
    }

    func removeLegacyAccount(_ account: ConnectedSocialAccount) async {
        do {
            try await service.removeLegacyPlaceholderAccount(account)
            await loadAccounts()
        } catch {
            print("Failed to remove legacy account: \(error.localizedDescription)")
        }
    }
}
