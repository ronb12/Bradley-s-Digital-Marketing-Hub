import SwiftUI

struct NotificationsOnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var enableReminders = true

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
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)

                VStack(spacing: 12) {
                    Text("Stay on schedule")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Get reminders when it's time to review and share your planned content.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 12) {
                    notificationRow(icon: "bell.badge.fill", title: "Post reminders", detail: "Nudge when content is due")
                    notificationRow(icon: "calendar.badge.clock", title: "Campaign tasks", detail: "Keep launches on track")
                }
                .padding()
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)

                Toggle(isOn: $enableReminders) {
                    Text("Enable reminders")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .white))
                .padding()
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    Task { await appViewModel.completeNotificationsOnboarding(enableReminders: enableReminders) }
                } label: {
                    Text("Continue to dashboard")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(colors.primary)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func notificationRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32)
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
