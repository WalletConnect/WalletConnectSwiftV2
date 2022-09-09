import UIKit

final class WelcomeRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentImport() {
        ImportModule.create(app: app)
            .wrapToNavigationController()
            .present()
    }

    func presentChats(account: Account) {
        ChatListModule.create(app: app, account: account)
            .wrapToNavigationController()
            .present()
    }
}
