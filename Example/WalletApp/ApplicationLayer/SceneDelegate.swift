import Auth
import SafariServices
import UIKit
import WalletConnectPairing

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
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

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()

        app.uri = WalletConnectURI(connectionOptions: connectionOptions)
        app.requestSent = (connectionOptions.urlContexts.first?.url.absoluteString.replacingOccurrences(of: "walletapp://wc?", with: "") == "requestSent")

        configurators.configure()

        UNUserNotificationCenter.current().delegate = self
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }

        let uri = WalletConnectURI(urlContext: context)

        if let uri {
            Task {
                try await Pair.instance.pair(uri: uri)
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        open(notification: notification)
        return [.sound, .banner, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        open(notification: response.notification)
    }
}

private extension SceneDelegate {

    func open(notification: UNNotification) {
        let popupTag: Int = 1020
        if let url = URL(string: notification.request.content.subtitle),
           let topController = window?.rootViewController?.topController, topController.view.tag != popupTag
        {
            let safari = SFSafariViewController(url: url)
            safari.modalPresentationStyle = .formSheet
            safari.view.tag = popupTag
            window?.rootViewController?.topController.present(safari, animated: true)
        }
    }
}
