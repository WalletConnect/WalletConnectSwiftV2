
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        if ClientDelegate.shared.client.getSettledSessions().count == 0 {
            showSelectChainScreen()
        } else {
            
        }
    }

    func showSelectChainScreen() {
        let vc = SelectChainViewController()
        vc.onSessionSettled = { [unowned self] session in
            DispatchQueue.main.async {
                showAccountsScreen(session)
            }
        }
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }
    
    func showAccountsScreen(_ session: Session) {
        window?.rootViewController = UINavigationController(rootViewController: ProposerViewController(session: session))
        window?.makeKeyAndVisible()
    }
    
}

