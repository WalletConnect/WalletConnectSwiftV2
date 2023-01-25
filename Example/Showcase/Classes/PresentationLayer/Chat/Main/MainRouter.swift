import UIKit

final class MainRouter {

    weak var viewController: UIViewController!

    private let app: Application

    var chatViewController: UIViewController {
        return WelcomeModule.create(app: app)
    }

    var web3InboxViewController: UIViewController {
        return Web3InboxModule.create(app: app)
    }

    init(app: Application) {
        self.app = app
    }
}
