import SwiftUI
import UIKit

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - Scene Delegate (injects ShakeDetectingWindow)
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Use our custom ShakeDetectingWindow instead of the default UIWindow
        let shakeWindow = ShakeDetectingWindow(windowScene: windowScene)

        let rootView = RootView()
            .environmentObject(AuthViewModel.shared)
            .environmentObject(EventProcessor.shared)
            .environmentObject(SensorManager.shared)
            .environmentObject(RouteTracker.shared)

        shakeWindow.rootViewController = UIHostingController(rootView: rootView)
        shakeWindow.makeKeyAndVisible()
        self.window = shakeWindow

        // Request notification permissions early
        AlertManager.shared.requestPermissions()
    }
}

// MARK: - App Entry Point
@main
struct EchoSaathApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // The actual UI is set up in SceneDelegate
            // This empty view is never displayed
            Color.clear
        }
    }
}
