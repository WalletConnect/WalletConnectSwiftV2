import UIKit

final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    func walletViewController() -> UIViewController {
        return WalletModule.create(app: app)
    }

    func notificationsViewController() -> UIViewController {
        return NotificationsModule.create(app: app)
            .wrapToNavigationController()
    }

    init(app: Application) {
        self.app = app
    }
}
