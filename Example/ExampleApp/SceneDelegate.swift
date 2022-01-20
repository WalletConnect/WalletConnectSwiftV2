import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UITabBarController.createExampleApp()
        window?.makeKeyAndVisible()
    }
}

extension UITabBarController {
    
    static func createExampleApp() -> UITabBarController {
        let responderController = UINavigationController(rootViewController: ResponderViewController())
        responderController.tabBarItem = UITabBarItem(title: "Wallet", image: UIImage(systemName: "dollarsign.circle"), selectedImage: nil)
        let proposerController = UINavigationController(rootViewController: ProposerViewController())
        proposerController.tabBarItem = UITabBarItem(title: "Dapp", image: UIImage(systemName: "appclip"), selectedImage: nil)
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [responderController]
        return tabBarController
    }
}
