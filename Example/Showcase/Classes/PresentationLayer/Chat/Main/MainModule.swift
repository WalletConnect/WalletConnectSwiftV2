import SwiftUI

final class MainModule {

    @discardableResult
    static func create(app: Application, importAccount: ImportAccount) -> UIViewController {
        let router = MainRouter(app: app)
        let presenter = MainPresenter(router: router, importAccount: importAccount)
        let viewController = MainViewController(presenter: presenter)

        router.viewController = viewController

        return viewController
    }

}
