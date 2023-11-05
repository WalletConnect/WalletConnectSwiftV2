import SwiftUI

final class SignModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = SignRouter(app: app)
        let interactor = SignInteractor()
        let presenter = SignPresenter(interactor: interactor, router: router)
        let view = SignView().environmentObject(presenter)
        
        let viewController = SceneViewController(viewModel: presenter, content: view)
        router.viewController = viewController

        return viewController
    }
}
