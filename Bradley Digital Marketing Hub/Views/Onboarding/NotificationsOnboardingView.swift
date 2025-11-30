import SwiftUI

struct NotificationsOnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var enableReminders = true

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Marketing nudges keep you on track.")
                .font(.title2).bold()
            Text("Opt in to daily reminders for campaign tasks, new templates, and affiliate drops.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Toggle("Enable reminders", isOn: $enableReminders)
                .toggleStyle(SwitchToggleStyle(tint: .hubBlue))
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Spacer()
            Button {
                Task { await appViewModel.completeNotificationsOnboarding(enableReminders: enableReminders) }
            } label: {
                Text("Continue to dashboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
