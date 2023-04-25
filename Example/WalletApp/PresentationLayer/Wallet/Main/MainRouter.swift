import UIKit
import WalletConnectPush
import Web3Wallet
final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    func walletViewController() -> UIViewController {
        return WalletModule.create(app: app)
            .wrapToNavigationController()
    }

    func present(proposal: Session.Proposal, context: Session.Context?) {
        SessionProposalModule.create(app: app, proposal: proposal, context: context)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }

    func notificationsViewController() -> UIViewController {
        return NotificationsModule.create(app: app)
            .wrapToNavigationController()
    }

    func present(pushRequest: PushRequest) {
        PushRequestModule.create(app: app, pushRequest: pushRequest)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }

    init(app: Application) {
        self.app = app
    }
}
