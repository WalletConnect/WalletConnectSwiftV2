import UIKit

final class MainRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func signViewController() -> UIViewController {
        return SignModule.create(app: app)
    }

    func authViewController() -> UIViewController {
        return AuthModule.create(app: app)
    }
}
