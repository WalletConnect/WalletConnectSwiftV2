import UIKit

final class TabViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewControllers = [
            createSignViewController(),
            createAuthViewController()
        ]
    }

    func createSignViewController() -> SignViewController {
        let controller = SignViewController()
        let item = UITabBarItem()
        item.title = "Sign"
        item.image = UIImage(systemName: "square")
        controller.tabBarItem = item
        return controller
    }

    func createAuthViewController() -> AuthViewController {
        let controller = AuthViewController()
        let item = UITabBarItem()
        item.title = "Auth"
        item.image = UIImage(systemName: "square")
        controller.tabBarItem = item
        return controller
    }
}
