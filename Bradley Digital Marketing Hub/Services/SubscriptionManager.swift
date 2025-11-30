import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var availableProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productIdentifiers: Set<String> = [
        SubscriptionTier.pro.productIdentifier!,
        SubscriptionTier.agency.productIdentifier!
    ]

    func loadProducts() async {
        do {
            availableProducts = try await Product.products(for: Array(productIdentifiers))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == SubscriptionTier.agency.productIdentifier {
                    currentTier = .agency
                } else if transaction.productID == SubscriptionTier.pro.productIdentifier {
                    currentTier = .pro
                }
                await transaction.finish()
            case .unverified:
                continue
            }
        }
    }

    func purchase(tier: SubscriptionTier) async {
        guard let productId = tier.productIdentifier else {
            currentTier = .free
            return
        }
        guard let product = availableProducts.first(where: { $0.id == productId }) else {
            errorMessage = "Product not available. Double-check StoreKit IDs."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                currentTier = tier
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func overrideTier(_ tier: SubscriptionTier) {
        // Used when syncing plan value from CloudKit profile.
        currentTier = tier
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed:
                return "Unable to verify this transaction."
            }
        }
    }
}
