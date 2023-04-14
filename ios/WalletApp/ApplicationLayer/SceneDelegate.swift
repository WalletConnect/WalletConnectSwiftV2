import UIKit
import Auth
import WalletConnectPairing


final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
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
          let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
          sceneConfig.delegateClass = SceneDelegate.self
          return sceneConfig
      }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()
        
        app.uri = connectionOptions.urlContexts.first?.url.absoluteString.replacingOccurrences(of: "walletapp://wc?uri=", with: "")

        configurators.configure()
        app.pushRegisterer.registerForPushNotifications()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }

        let uri = context.url.absoluteString.replacingOccurrences(of: "walletapp://wc?uri=", with: "")
        Task {
            try await Pair.instance.pair(uri: WalletConnectURI(string: uri)!)
        }

    }
}
