import SwiftUI
import Auth

final class AuthCoordinator {

    let navigationController = UINavigationController()

    private lazy var tabBarItem: UITabBarItem = {
        let item = UITabBarItem()
        item.title = "Auth"
        item.image = UIImage(systemName: "person")
        return item
    }()

    private lazy var authViewController: UIViewController = {
        let viewModel = AuthViewModel()
        let view = AuthView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        controller.title = "DApp"
        return controller
    }()

    func start() {
        navigationController.tabBarItem = tabBarItem
        navigationController.viewControllers = [UIViewController()]

        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "WalletConnect DApp sample",
            url: "wallet.connect",
            icons: ["https://avatars.githubusercontent.com/u/37784886"])

        Auth.configure(metadata: metadata, account: nil)

        navigationController.viewControllers = [authViewController]
    }
}
