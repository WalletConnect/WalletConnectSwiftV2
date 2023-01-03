import UIKit

final class WelcomeRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
    
    func presentWallet() {
        WalletModule.create(app: app)
            .wrapToNavigationController()
            .presentFullScreen(from: viewController)
    }
}
