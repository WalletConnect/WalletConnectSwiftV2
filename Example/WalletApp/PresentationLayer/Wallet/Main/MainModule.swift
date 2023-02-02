import SwiftUI

final class MainModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = MainRouter(app: app)
        let interactor = MainInteractor()
        let presenter = MainPresenter(router: router, interactor: interactor)
        let viewController = MainViewController(presenter: presenter)

        router.viewController = viewController

        return viewController
    }

}
