import UIKit

final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    func walletViewController() -> UIViewController {
        return WalletModule.create(app: app)
    }

    func notificationsViewController() -> UIViewController {
        return WalletModule.create(app: app)
//        return Web3InboxModule.create(app: app, account: account).wrapToNavigationController()
    }

    init(app: Application) {
        self.app = app
    }
}
