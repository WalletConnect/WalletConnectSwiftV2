import UIKit

import WalletConnectSign

final class SessionAccountRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
    
    func dismiss() {
        viewController.dismiss(animated: true)
    }
}
