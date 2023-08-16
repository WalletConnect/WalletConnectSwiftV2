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
    
    func present(proposal: Session.Proposal, importAccount: ImportAccount, context: VerifyContext?) {
        SessionProposalModule.create(app: app, importAccount: importAccount, proposal: proposal, context: context)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }
    
    func present(sessionRequest: Request, importAccount: ImportAccount, sessionContext: VerifyContext?) {
        SessionRequestModule.create(app: app, sessionRequest: sessionRequest, importAccount: importAccount, sessionContext: sessionContext)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }

    func present(request: AuthRequest, importAccount: ImportAccount, context: VerifyContext?) {
        AuthRequestModule.create(app: app, request: request, importAccount: importAccount, context: context)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }
}
