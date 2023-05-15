import UIKit

import Web3Wallet

final class ConnectionDetailsRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func present(request: AuthRequest, context: VerifyContext) {
        AuthRequestModule.create(app: app, request: request, context: context)
            .wrapToNavigationController()
            .present(from: viewController)
    }

    func presentScan(onValue: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        ScanModule.create(app: app, onValue: onValue, onError: onError)
            .wrapToNavigationController()
            .present(from: viewController)
    }

    func dismiss() {
        viewController.navigationController?.popViewController(animated: true)
    }
}
