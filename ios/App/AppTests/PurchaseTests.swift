import XCTest
import StoreKit
import StoreKitTest
@testable import App

/// End-to-end checks of the money path against Products.storekit:
/// free tier → purchase → everything unlocked → refund → locked again.
@MainActor
final class PurchaseTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        PurchaseManager.paywallEnabled = true
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        await waitForStoreIdle()
        await PurchaseManager.shared.refreshEntitlements()
    }

    override func tearDown() async throws {
        PurchaseManager.paywallEnabled = false
    }

    /// The singleton starts loading at app launch; wait so tests don't race it.
    private func waitForStoreIdle() async {
        for _ in 0..<50 where PurchaseManager.shared.loadState == .loading {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    /// SKTestSession sometimes can't reach the simulator's StoreKit service
    /// (SKInternalErrorDomain 3). Skip, loudly, instead of reporting a false failure.
    private func requireStoreKit() async throws {
        let products = try await Product.products(for: [PurchaseManager.productID])
        try XCTSkipIf(products.isEmpty,
                      "StoreKit test environment unavailable on this simulator — run these tests from Xcode")
    }

    func testProductIsConfiguredAsNonConsumable() async throws {
        try await requireStoreKit()
        let products = try await Product.products(for: [PurchaseManager.productID])
        let product = try XCTUnwrap(products.first)
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertFalse(product.displayPrice.isEmpty)
    }

    func testFreeTierShowsOnlyAnimals() {
        let store = PurchaseManager.shared
        let savedDevUnlock = store.developerUnlock
        store.developerUnlock = false
        defer { store.developerUnlock = savedDevUnlock }
        XCTAssertFalse(store.isUnlocked)
        XCTAssertEqual(ALL_CATEGORIES.filter { store.isAvailable($0) }.map(\.id), [FREE_CATEGORY_ID])
        XCTAssertEqual(store.availableWords.count,
                       ALL_CATEGORIES.first { $0.id == FREE_CATEGORY_ID }!.words.count)
        XCTAssertGreaterThanOrEqual(store.availableWords.count, 2, "Find it! needs at least 2 free words")
    }

    func testPurchaseUnlocksEverythingAndRefundLocksAgain() async throws {
        try await requireStoreKit()
        let store = PurchaseManager.shared
        XCTAssertFalse(store.isUnlocked)

        await store.purchase()
        XCTAssertNil(store.errorMessage)
        XCTAssertTrue(store.isUnlocked)
        XCTAssertTrue(ALL_CATEGORIES.allSatisfy { store.isAvailable($0) })
        XCTAssertEqual(store.availableWords.count, ALL_WORDS.count)

        // Refund → entitlement revoked → content locks again.
        let tx = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == PurchaseManager.productID })
        try session.refundTransaction(identifier: tx.identifier)
        await store.refreshEntitlements()
        XCTAssertFalse(store.isUnlocked)
    }

    /// Restore relies on Transaction.currentEntitlements. AppStore.sync() itself shows an
    /// Apple Account sign-in prompt that blocks unattended tests, so it is not called here.
    func testEntitlementSurvivesLosingLocalFlag() async throws {
        try await requireStoreKit()
        let store = PurchaseManager.shared
        await store.purchase()
        XCTAssertTrue(store.isUnlocked)
        // Simulate a fresh install: forget the cached flag, then re-read entitlements.
        UserDefaults.standard.removeObject(forKey: "isUnlocked")
        await store.refreshEntitlements()
        XCTAssertTrue(store.isUnlocked)
    }
}

@MainActor
final class PaywallOffTests: XCTestCase {
    func testWithPaywallOffEveryWorldIsOpen() {
        XCTAssertFalse(PurchaseManager.paywallEnabled, "Paywall is meant to be off for now")
        let store = PurchaseManager.shared
        XCTAssertTrue(ALL_CATEGORIES.allSatisfy { store.isAvailable($0) })
        XCTAssertEqual(store.availableWords.count, ALL_WORDS.count)
    }
}
