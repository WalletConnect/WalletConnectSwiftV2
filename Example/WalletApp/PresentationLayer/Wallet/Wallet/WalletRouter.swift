import UIKit

import Web3Wallet

final class WalletRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
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
    
    func presentPaste(onValue: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        PasteUriModule.create(app: app, onValue: onValue, onError: onError)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }
    
    func presentConnectionDetails(session: Session) {
        ConnectionDetailsModule.create(app: app, session: session)
            .push(from: viewController)
    }

    func presentScan(onValue: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        ScanModule.create(app: app, onValue: onValue, onError: onError)
            .wrapToNavigationController()
            .present(from: viewController)
    }

    func dismiss() {
        viewController.navigationController?.dismiss()
    }
}
