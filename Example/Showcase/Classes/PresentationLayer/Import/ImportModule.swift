import SwiftUI

final class ImportModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = ImportRouter(app: app)
        let interactor = ImportInteractor(registerService: app.registerService, accountStorage: app.accountStorage)
        let presenter = ImportPresenter(interactor: interactor, router: router)
        let view = ImportView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
