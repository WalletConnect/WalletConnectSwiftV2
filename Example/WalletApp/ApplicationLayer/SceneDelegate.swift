import SafariServices
import UIKit
import Web3Wallet
import WalletConnectSign

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

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        do {
            try Web3Wallet.instance.dispatchEnvelope(url.absoluteString)
        } catch {
            print(error)
        }
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Setup the window
        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()

        // Notification center delegate setup
        UNUserNotificationCenter.current().delegate = self

        configureWeb3WalletClientIfNeeded()
        app.requestSent = (connectionOptions.urlContexts.first?.url.absoluteString.replacingOccurrences(of: "walletapp://wc?", with: "") == "requestSent")

        // Process connection options
        do {
            // Attempt to initialize WalletConnectURI from connection options
            let uri = try WalletConnectURI(connectionOptions: connectionOptions)
            app.uri = uri
        } catch {
            print("Error initializing WalletConnectURI: \(error.localizedDescription)")
            // Try to handle link mode in case where WalletConnectURI initialization fails
            if let url = connectionOptions.userActivities.first?.webpageURL {
                configurators.configure() // Ensure configurators are set up before dispatching
                do {
                    try Web3Wallet.instance.dispatchEnvelope(url.absoluteString)
                } catch {
                    print("Error dispatching envelope: \(error.localizedDescription)")
                }
                return
            }
        }
        configurators.configure()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }
        
        let url = context.url

        do {
            let uri = try WalletConnectURI(urlContext: context)
            Task {
                try await Web3Wallet.instance.pair(uri: uri)
            }
        } catch {
            if case WalletConnectURI.Errors.expired = error {
                AlertPresenter.present(message: error.localizedDescription, type: .error)
            } else {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let queryItems = components.queryItems,
                      queryItems.contains(where: { $0.name == "wc_ev" }) else {
                    return
                }

                do {
                    try Web3Wallet.instance.dispatchEnvelope(url.absoluteString)
                } catch {
                    AlertPresenter.present(message: error.localizedDescription, type: .error)
                }
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

    func configureWeb3WalletClientIfNeeded() {
        Networking.configure(
            groupIdentifier: "group.com.walletconnect.sdk",
            projectId: InputConfig.projectId,
            socketFactory: DefaultSocketFactory()
        )

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"],
            redirect: try! AppMetadata.Redirect(native: "walletapp://", universal: "https://lab.web3modal.com/wallet", linkMode: true)
        )

        Web3Wallet.configure(metadata: metadata, crypto: DefaultCryptoProvider(), environment: BuildConfiguration.shared.apnsEnvironment)

    }
}
