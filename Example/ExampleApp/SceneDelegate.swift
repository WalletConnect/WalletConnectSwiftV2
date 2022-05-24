import UIKit
import WalletConnectSign

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"])
        Auth.configure(Auth.Config(metadata: metadata, projectId: "8ba9ee138960775e5231b70cc5ef1c3a"))
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UITabBarController.createExampleApp()
        window?.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else  {
                  return
              }
        let wcUri = incomingURL.absoluteString.deletingPrefix("https://walletconnect.com/wc?uri=")
        let vc = ((window!.rootViewController as! UINavigationController).viewControllers[0] as! WalletViewController)
        vc.onClientConnected = {
            Task {
                do {
                    try await Auth.instance.pair(uri: wcUri)
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension UITabBarController {
    
    static func createExampleApp() -> UINavigationController    {
        let responderController = UINavigationController(rootViewController: WalletViewController())
        return responderController
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
