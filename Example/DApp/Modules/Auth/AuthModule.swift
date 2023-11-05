import SwiftUI

final class AuthModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = AuthRouter(app: app)
        let interactor = AuthInteractor()
        let presenter = AuthPresenter(interactor: interactor, router: router)
        let view = AuthView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
