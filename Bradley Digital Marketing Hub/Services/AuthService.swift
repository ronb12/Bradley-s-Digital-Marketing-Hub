import Foundation
import AuthenticationServices

struct AuthPayload {
    let userId: String
    let fullName: PersonNameComponents?
    let email: String?
}

/// Handles Sign in with Apple orchestration and local caching of user identifiers.
final class AuthService: NSObject {
    private let userDefaultsKey = "BradleyDigitalMarketingHub.lastAppleUserId"

    func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func payload(from authorization: ASAuthorization) throws -> AuthPayload {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw CloudKitError.operationFailed("Unsupported authorization credential")
        }
        let payload = AuthPayload(userId: credential.user, fullName: credential.fullName, email: credential.email)
        cache(userId: credential.user)
        return payload
    }

    func cachedUserId() -> String? {
        UserDefaults.standard.string(forKey: userDefaultsKey)
    }

    func cache(userId: String) {
        UserDefaults.standard.set(userId, forKey: userDefaultsKey)
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    func credentialState(for userId: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }
}
