import Foundation
import StoreKit

/// One-time, non-consumable "Unlock Everything" purchase (StoreKit 2).
///
/// Business model: the Animals world and every game are free forever, so a
/// family can fall in love with the app before paying. One payment unlocks
/// every world — no subscription, no ads, Family Sharing on.
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    /// Must match the product created in App Store Connect and in Products.storekit.
    static let productID = "com.babyenglish.app.fullunlock"

    enum LoadState: Equatable { case idle, loading, loaded, failed }

    @Published private(set) var product: Product?
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var isPurchasing = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?
    private let unlockedKey = "isUnlocked"

    private init() {
        isUnlocked = UserDefaults.standard.bool(forKey: unlockedKey)
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task {
            await refreshEntitlements()
            await loadProduct()
        }
    }

    deinit { updatesTask?.cancel() }

    var displayPrice: String? { product?.displayPrice }

    func isAvailable(_ category: Category) -> Bool {
        isUnlocked || category.isFree
    }

    /// Words children can see in games right now.
    var availableWords: [WordItem] {
        ALL_CATEGORIES.filter { isAvailable($0) }.flatMap { $0.words }
    }

    func loadProduct() async {
        guard product == nil, loadState != .loading else { return }
        loadState = .loading
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            loadState = product == nil ? .failed : .loaded
        } catch {
            loadState = .failed
        }
    }

    func purchase() async {
        if product == nil { await loadProduct() }
        guard let product else {
            errorMessage = L10n.t("The App Store isn't reachable right now. Please try again in a moment.",
                                  "אין חיבור ל-App Store כרגע. נסו שוב בעוד רגע.")
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .pending:
                errorMessage = L10n.t("Your purchase is waiting for approval. It will unlock automatically.",
                                      "הרכישה ממתינה לאישור. התוכן ייפתח אוטומטית.")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = L10n.t("Something went wrong. You were not charged.",
                                  "משהו השתבש. לא בוצע חיוב.")
        }
    }

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await AppStore.sync()
        await refreshEntitlements()
        if !isUnlocked {
            errorMessage = L10n.t("No previous purchase was found for this Apple ID.",
                                  "לא נמצאה רכישה קודמת עבור ה-Apple ID הזה.")
        }
    }

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID, t.revocationDate == nil {
                owned = true
            }
        }
        setUnlocked(owned)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.productID {
            setUnlocked(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func setUnlocked(_ value: Bool) {
        guard value != isUnlocked else { return }
        isUnlocked = value
        UserDefaults.standard.set(value, forKey: unlockedKey)
    }
}
