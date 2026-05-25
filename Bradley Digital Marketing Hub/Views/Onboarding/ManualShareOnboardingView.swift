import SwiftUI

struct ManualShareOnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [colors.primary, colors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                HubAppLogo(size: 96, cornerRadius: 22)

                VStack(spacing: 10) {
                    Text("Plan here. Publish there.")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Bradley Hub is your scheduling command center. When it's time to post, you'll share manually through each platform's app — just like the pros do on mobile.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 14) {
                    stepRow(number: 1, icon: "calendar.badge.plus", title: "Plan in your calendar", detail: "Write captions and pick dates like Buffer or Later.")
                    stepRow(number: 2, icon: "bell.badge.fill", title: "Get a reminder", detail: "We'll nudge you when it's time to publish.")
                    stepRow(number: 3, icon: "square.and.arrow.up", title: "Share via iOS Share Sheet", detail: "Pick Instagram, TikTok, Facebook, or any installed app.")
                    stepRow(number: 4, icon: "checkmark.circle.fill", title: "Mark as shared", detail: "Keep your queue accurate and your analytics honest.")
                }
                .padding()
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    appViewModel.completeManualShareOnboarding()
                } label: {
                    Text("Got it — continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(colors.primary)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .accessibilityIdentifier("manual_share_continue_button")
            }
        }
        .accessibilityIdentifier("manual_share_onboarding")
    }

    private func stepRow(number: Int, icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(.white.opacity(0.2), in: Circle())
                .foregroundColor(.white)
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
    }
}
