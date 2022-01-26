import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UITabBarController.createExampleApp()
        window?.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let url = URLContexts.first?.url
        let urlString: String = url!.absoluteString
        let wcUri = urlString.deletingPrefix("walletconnectwallet:")
        let client = ((window!.rootViewController as! UINavigationController).viewControllers[0] as! ResponderViewController).client
        try? client.pair(uri: wcUri)
    }
}

extension UITabBarController {
    
    static func createExampleApp() -> UINavigationController    {
        let responderController = UINavigationController(rootViewController: ResponderViewController())
        return responderController
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
