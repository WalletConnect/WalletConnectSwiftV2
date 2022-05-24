
import UIKit
import WalletConnectSign
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var publishers = [AnyCancellable]()


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "a description",
            url: "wallet.connect",
            icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"])
        Auth.configure(Auth.Config(metadata: metadata, projectId: "8ba9ee138960775e5231b70cc5ef1c3a"))
        Auth.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                showSelectChainScreen()
            }.store(in: &publishers)
        
        Auth.instance.sessionResponsePublisher.sink { [unowned self] response in
            presentResponse(for: response)
        }.store(in: &publishers)

        
        if let session = Auth.instance.getSettledSessions().first {
            showAccountsScreen(session)
        } else {
            showSelectChainScreen()
        }
    }

    func showSelectChainScreen() {
        DispatchQueue.main.async { [unowned self] in
            let vc = SelectChainViewController()
            vc.onSessionSettled = { [unowned self] session in
                showAccountsScreen(session)
            }
            window?.rootViewController = UINavigationController(rootViewController: vc)
            window?.makeKeyAndVisible()
        }
    }
    
    func showAccountsScreen(_ session: Session) {
        DispatchQueue.main.async { [unowned self] in
            let vc = AccountsViewController(session: session)
            vc.onDisconnect = { [unowned self]  in
                showSelectChainScreen()
            }
            window?.rootViewController = UINavigationController(rootViewController: vc)
            window?.makeKeyAndVisible()
        }
    }
    
    func presentResponse(for response: Response) {
        DispatchQueue.main.async { [unowned self] in
            let vc = UINavigationController(rootViewController: ResponseViewController(response: response))
            window?.rootViewController?.present(vc, animated: true, completion: nil)
        }
    }
}

