import SwiftUI

final class MainModule {

    @discardableResult
    static func create(app: Application, account: Account) -> UIViewController {
        let router = MainRouter(app: app)
        let presenter = MainPresenter(router: router, account: account)
        let viewController = MainViewController(presenter: presenter)

        router.viewController = viewController

        return viewController
    }

}
