import UIKit

import Web3Wallet
import WalletConnectPush

final class MainRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func walletViewController() -> UIViewController {
        return WalletModule.create(app: app)
            .wrapToNavigationController()
    }

    func notificationsViewController() -> UIViewController {
        return NotificationsModule.create(app: app)
            .wrapToNavigationController()
    }

    func web3InboxViewController() -> UIViewController {
        return Web3InboxModule.create(app: app)
            .wrapToNavigationController()
    }

    func present(pushRequest: PushRequest) {
//        PushRequestModule.create(app: app, pushRequest: pushRequest)
//            .presentFullScreen(from: viewController, transparentBackground: true)
    }
}
