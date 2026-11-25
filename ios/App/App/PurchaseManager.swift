import Foundation
import StoreKit
import UIKit

/// One-time, non-consumable "Unlock Everything" purchase (StoreKit 2).
///
/// Business model: the Animals world and every game are free forever, so a
/// family can fall in love with the app before paying. One payment unlocks
/// every world — no subscription, no ads, Family Sharing on.
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    /// Must match the product created in App Store Connect and in Products.storekit.
    static let productID = "com.pipenglish.app.fullunlock"

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
        #if DEBUG
        // `-developerUnlock` at launch (from Xcode or devicectl) turns the dev unlock on and keeps it on.
        if ProcessInfo.processInfo.arguments.contains("-developerUnlock") {
            developerUnlock = true
            UserDefaults.standard.set(true, forKey: "developerUnlock")
        }
        #endif
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

    /// Everything is open: bought (or redeemed with a code), or a developer build with the dev unlock on.
    var hasFullAccess: Bool { isUnlocked || developerUnlock }

    func isAvailable(_ category: Category) -> Bool {
        hasFullAccess || category.isFree
    }

    // MARK: Developer unlock (Debug builds only)

    #if DEBUG
    /// For the developer's own phone (installed from Xcode): open every world
    /// without paying. Compiled out of App Store builds, so it can never ship.
    @Published var developerUnlock: Bool = UserDefaults.standard.bool(forKey: "developerUnlock") {
        didSet { UserDefaults.standard.set(developerUnlock, forKey: "developerUnlock") }
    }
    #else
    let developerUnlock = false
    #endif

    // MARK: Offer codes

    /// Free codes for friends and family, created in App Store Connect
    /// ("Offer Codes" on the full-unlock purchase). Apple shows its own
    /// redemption sheet; a redeemed code arrives through Transaction.updates
    /// exactly like a purchase. Non-consumable codes redeem on iOS 16.3+.
    func redeemCode() async {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        do {
            try await AppStore.presentOfferCodeRedeemSheet(in: scene)
        } catch {
            errorMessage = L10n.t("The code screen couldn't open right now. Please try again in a moment.",
                                  "מסך הקוד לא נפתח כרגע. נסו שוב בעוד רגע.")
        }
        await refreshEntitlements()
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
