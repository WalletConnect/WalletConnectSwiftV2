import UIKit
import Combine
import WalletConnectNotify

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private var publishers = [AnyCancellable]()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let entryPointAddress = "0x0000000071727De22E5E9d8BAf0edAc6f37da032" // v0.7 on Sepolia
        let chainId = 11155111 // Sepolia
        SmartAccount.instance.configure(entryPoint: entryPointAddress, chainId: chainId)
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

        let deviceTokenString = deviceToken.map { data in String(format: "%02.2hhx", data) }
        UserDefaults.standard.set(deviceTokenString.joined(), forKey: "deviceToken")

        Task(priority: .high) {            
            try await Notify.instance.register(deviceToken: deviceToken, enableEncrypted: true)
        }
    }

    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
    }
}
