import UIKit

import Web3Wallet
import WalletConnectPush

final class MainRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func walletViewController(importAccount: ImportAccount) -> UIViewController {
        return WalletModule.create(app: app, importAccount: importAccount)
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

    func settingsViewController() -> UIViewController {
        return SettingsModule.create(app: app)
            .wrapToNavigationController()
    }

    func present(pushRequest: PushRequest) {
//        PushRequestModule.create(app: app, pushRequest: pushRequest)
//            .presentFullScreen(from: viewController, transparentBackground: true)
    }
}
