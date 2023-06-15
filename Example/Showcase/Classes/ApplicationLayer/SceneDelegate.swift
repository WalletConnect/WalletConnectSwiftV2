import UIKit
import Auth
import WalletConnectPairing

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIApplicationDelegate {

    var window: UIWindow?

    private let app = Application()

    private var configurators: [Configurator] {
        return [
            MigrationConfigurator(app: app),
            ThirdPartyConfigurator(),
            ApplicationConfigurator(app: app),
            AppearanceConfigurator()
        ]
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        UIApplication.shared.delegate = self

        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()

        configurators.configure()

        app.pushRegisterer.registerForPushNotifications()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }

        let uri = context.url.absoluteString.replacingOccurrences(of: "showcase://wc?uri=", with: "")
        guard let walletConnectUri = WalletConnectURI(string: uri) else {
            return
        }
        
        Task {
            try await Pair.instance.pair(uri: walletConnectUri)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task(priority: .high) {
            try await app.chatService.register(deviceToken: deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
}
