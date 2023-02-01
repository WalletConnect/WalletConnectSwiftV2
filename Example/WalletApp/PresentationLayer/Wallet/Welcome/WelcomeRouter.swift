import UIKit

final class WelcomeRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
    
    func presentWallet() {
        MainModule.create(app: app)
            .present()
    }
}
