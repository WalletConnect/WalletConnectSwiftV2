import UIKit
import Combine
import WalletConnectSign
import WalletConnectRelay
import WalletConnectPairing

final class SignCoordinator {

    private var publishers = Set<AnyCancellable>()

    let navigationController = UINavigationController()

    lazy var tabBarItem: UITabBarItem = {
        let item = UITabBarItem()
        item.title = "Sign"
        item.image = UIImage(systemName: "signature")
        return item
    }()

    func start() {
        navigationController.tabBarItem = tabBarItem

        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "WalletConnect DApp sample",
            url: "wallet.connect",
            icons: ["https://avatars.githubusercontent.com/u/37784886"])

        Pair.configure(metadata: metadata)
#if DEBUG
        if CommandLine.arguments.contains("-cleanInstall") {
            try? Sign.instance.cleanup()
        }
#endif

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                showSelectChainScreen()
            }.store(in: &publishers)

        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] response in
                presentResponse(for: response)
            }.store(in: &publishers)

        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] session in
                let vc = showAccountsScreen(session)
                vc.proposePushSubscription()
            }.store(in: &publishers)

        if let session = Sign.instance.getSessions().first {
            _ = showAccountsScreen(session)
        } else {
            showSelectChainScreen()
        }
    }

    private func showSelectChainScreen() {
        let controller = SelectChainViewController()
        navigationController.viewControllers = [controller]
    }

    private func showAccountsScreen(_ session: Session) -> AccountsViewController {
        let controller = AccountsViewController(session: session)
        controller.onDisconnect = { [unowned self]  in
            showSelectChainScreen()
        }
        navigationController.presentedViewController?.dismiss(animated: false)
        navigationController.viewControllers = [controller]
        return controller
    }

    private func presentResponse(for response: Response) {
        let controller = UINavigationController(rootViewController: ResponseViewController(response: response))
        navigationController.present(controller, animated: true, completion: nil)
    }
}
