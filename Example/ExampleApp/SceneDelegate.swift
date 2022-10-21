import UIKit
import Foundation
import Combine
import WalletConnectSign
import WalletConnectNetworking
import WalletConnectRelay
import WalletConnectPairing
import Starscream

extension WebSocket: WebSocketConnecting { }

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"])

        Networking.configure(projectId: InputConfig.projectId, socketFactory: SocketFactory())
        Pair.configure(metadata: metadata)
#if DEBUG
        if CommandLine.arguments.contains("-cleanInstall") {
            try? Sign.instance.cleanup()
        }
#endif

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UITabBarController.createExampleApp()
        window?.makeKeyAndVisible()

        if let userActivity = connectionOptions.userActivities.first {
            handle(userActivity: userActivity)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(userActivity: userActivity)
    }

    private func handle(userActivity: NSUserActivity) {
        guard
            let url = userActivity.webpageURL,
            userActivity.activityType == NSUserActivityTypeBrowsingWeb
        else { return }

        let wcUri = url.absoluteString.deletingPrefix("https://walletconnect.com/wc?uri=")
        Task(priority: .high) {
            try! await Pair.instance.pair(uri: WalletConnectURI(string: wcUri)!)
        }
    }
}

extension UITabBarController {

    static func createExampleApp() -> UINavigationController {
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
