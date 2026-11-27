import UIKit
import SwiftUI

// ─────────────────────────────────────────────
// MARK: - App Entry Point
// ─────────────────────────────────────────────

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AudioManager.shared.configureSession()
        AudioManager.shared.updateMusic()
        Task { @MainActor in _ = PurchaseManager.shared }
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = BabyHostingController(rootView: AnyView(RootView()))
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        AudioManager.shared.enterBackground()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        AudioManager.shared.enterForeground()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        StickerStore.shared.updateStreak()
        Task { @MainActor in await PurchaseManager.shared.refreshEntitlements() }
    }
}

/// Hosting controller tuned for little hands:
/// - hides the status bar and home indicator (fewer things to poke)
/// - defers system edge gestures so a stray swipe from the bottom edge
///   needs a second, deliberate swipe to leave the app.
final class BabyHostingController: UIHostingController<AnyView> {
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
}
