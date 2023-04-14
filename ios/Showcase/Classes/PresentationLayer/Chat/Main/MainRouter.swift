import UIKit

final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    func chatViewController(account: Account) -> UIViewController {
        return ChatListModule.create(app: app, account: account).wrapToNavigationController()
    }

    func web3InboxViewController(importAccount: ImportAccount) -> UIViewController {
        return Web3InboxModule.create(app: app, importAccount: importAccount).wrapToNavigationController()
    }

    init(app: Application) {
        self.app = app
    }
}
