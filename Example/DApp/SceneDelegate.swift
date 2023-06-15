import UIKit
import Auth
import WalletConnectRelay
import WalletConnectNetworking

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private let signCoordinator = SignCoordinator()
    private let authCoordinator = AuthCoordinator()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        Networking.configure(projectId: InputConfig.projectId)
        Auth.configure(crypto: DefaultCryptoProvider())

        setupWindow(scene: scene)
    }

    private func setupWindow(scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let tabController = UITabBarController()
        tabController.viewControllers = [
            signCoordinator.navigationController,
            authCoordinator.navigationController
        ]

        signCoordinator.start()
        authCoordinator.start()

        window?.rootViewController = tabController
        window?.makeKeyAndVisible()
    }
}
