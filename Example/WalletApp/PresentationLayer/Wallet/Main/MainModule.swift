import SwiftUI

final class MainModule {
    @discardableResult
    static func create(app: Application, importAccount: ImportAccount) -> UIViewController {
        let router = MainRouter(app: app)
        let interactor = MainInteractor()
        let presenter = MainPresenter(router: router, interactor: interactor, importAccount: importAccount, pushRegisterer: app.pushRegisterer, configurationService: app.configurationService)
        let viewController = MainViewController(presenter: presenter)

        router.viewController = viewController

        return viewController
    }
}
