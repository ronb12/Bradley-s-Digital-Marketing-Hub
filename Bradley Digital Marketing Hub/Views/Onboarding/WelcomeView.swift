import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 12) {
                Text("Bradley Digital Marketing Hub")
                    .font(.largeTitle).bold()
                    .multilineTextAlignment(.center)
                Text("Plan campaigns, generate content, and grow with Apple-native tools.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            Spacer()
            SignInWithAppleButton(.continue) { request in
                appViewModel.prepareSignInRequest(request)
            } onCompletion: { result in
                appViewModel.handleSignInResult(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            Text("We use Sign in with Apple to securely create your marketing workspace.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
