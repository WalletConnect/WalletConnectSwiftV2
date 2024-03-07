import UIKit

import WalletConnectSign

final class SignRouter {
    weak var viewController: UIViewController!
    
    private var newPairingViewController: UIViewController?

    private let app: Application

    init(app: Application) {
        self.app = app
    }
    
    func presentNewPairing(walletConnectUri: WalletConnectURI) {
        newPairingViewController = NewPairingModule.create(app: app, walletConnectUri: walletConnectUri)
        newPairingViewController?.present(from: viewController)
    }
    
    func presentSessionAccount(sessionAccount: AccountDetails, session: Session) {
        SessionAccountModule.create(app: app, sessionAccount: sessionAccount, session: session)
            .push(from: viewController)
    }

    func dismissNewPairing() {
        newPairingViewController?.dismiss()
    }

    func dismiss() {
        viewController.dismiss(animated: true)
    }

    func popToRoot() {
        viewController.popToRoot()
    }
}
