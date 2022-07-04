import SwiftUI

final class MainModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = MainRouter(app: app)
        let presenter = MainPresenter(router: router)
        let viewController = MainViewController(presenter: presenter)

        router.viewController = viewController

        return viewController
    }

}
