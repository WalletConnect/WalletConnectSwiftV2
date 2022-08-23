import UIKit
import Auth

final class WalletRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func present(request: AuthRequest) {
        AuthRequestModule.create(app: app, request: request).present(from: viewController)
    }
}
