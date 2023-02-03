import UIKit

final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    func chatViewController(account: Account) -> UIViewController {
        return ChatListModule.create(app: app, account: account).wrapToNavigationController()
    }

    func web3InboxViewController(account: Account) -> UIViewController {
        return Web3InboxModule.create(app: app, account: account).wrapToNavigationController()
    }

    init(app: Application) {
        self.app = app
    }
}
