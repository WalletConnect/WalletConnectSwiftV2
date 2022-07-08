import UIKit

final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    var chatViewController: UIViewController {
        return ChatListModule.create(app: app).wrapToNavigationController()
    }

    init(app: Application) {
        self.app = app
    }
}
