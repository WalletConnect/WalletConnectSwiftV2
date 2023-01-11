import UIKit

final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    var chatViewController: UIViewController {
        return WelcomeModule.create(app: app)
    }

    init(app: Application) {
        self.app = app
    }
}
