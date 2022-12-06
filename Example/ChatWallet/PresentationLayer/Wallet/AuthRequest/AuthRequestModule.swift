import SwiftUI
import Auth

final class AuthRequestModule {

    @discardableResult
    static func create(app: Application, request: AuthRequest) -> UIViewController {
        let router = AuthRequestRouter(app: app)
        let interactor = AuthRequestInteractor()
        let presenter = AuthRequestPresenter(request: request, interactor: interactor, router: router)
        let view = AuthRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
