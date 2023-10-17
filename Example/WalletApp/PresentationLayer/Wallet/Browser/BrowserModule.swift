import SwiftUI

final class BrowserModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = BrowserRouter(app: app)
        let interactor = BrowserInteractor()
        let presenter = BrowserPresenter(interactor: interactor, router: router)
        let view = BrowserView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
