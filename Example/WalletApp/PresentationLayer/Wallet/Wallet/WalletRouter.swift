import UIKit

import Web3Wallet
import WalletConnectPush

final class WalletRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func present(request: AuthRequest) {
        AuthRequestModule.create(app: app, request: request)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }
    
    func present(proposal: Session.Proposal) {
        SessionProposalModule.create(app: app, proposal: proposal)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }
    
    func present(sessionRequest: Request) {
        SessionRequestModule.create(app: app, sessionRequest: sessionRequest)
            .presentFullScreen(from: viewController, transparentBackground: true)
    }

    func present(pushRequest: PushRequest) {
        PushRequestModule.create(app: app, pushRequest: pushRequest)
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
