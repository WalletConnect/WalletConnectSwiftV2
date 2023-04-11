import UIKit
import WalletConnectPush
import Combine

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private var publishers = [AnyCancellable]()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-disableAnimations") {
            UIView.setAnimationsEnabled(false)
            UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .last { $0.isKeyWindow }?.layer.speed = 200
        }
        #endif
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        
        Task(priority: .high) {
            // Use pasteboard for testing purposes
            let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
            let token = tokenParts.joined()
            // Commenting this out as it breaks UI tests that copy/paste URI
//            let pasteboard = UIPasteboard.general
//            pasteboard.string = token
            try await Push.wallet.register(deviceToken: deviceToken)
        }
    }

    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
    }

}
