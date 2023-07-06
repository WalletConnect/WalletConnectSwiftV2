import UIKit
import Auth
import WalletConnectRelay
import WalletConnectNetworking
import WalletConnectModal

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private let signCoordinator = SignCoordinator()
    private let authCoordinator = AuthCoordinator()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())
        Auth.configure(crypto: DefaultCryptoProvider())
        
        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "WalletConnect DApp sample",
            url: "wallet.connect",
            icons: ["https://avatars.githubusercontent.com/u/37784886"]
        )
        
        WalletConnectModal.configure(
            projectId: InputConfig.projectId, 
            metadata: metadata,
            recommendedWalletIds: [
                "1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369", // Rainbow
                "ecc4036f814562b41a5268adc86270fba1365471402006302e70169465b7ac18", // Zerion
                "c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96", // Metamask
                "c286eebc742a537cd1d6818363e9dc53b21759a1e8e5d9b263d0c03ec7703576", // 1inch
                "ef333840daf915aafdc4a004525502d6d49d77bd9c65e0642dbaefb3c2893bef", // imToken
                
            ],
            excludedWalletIds: []
        )

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
