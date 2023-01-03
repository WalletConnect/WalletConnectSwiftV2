import SwiftUI

final class WelcomeModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = WelcomeRouter(app: app)
        let interactor = WelcomeInteractor()
        let presenter = WelcomePresenter(interactor: interactor, router: router)
        let view = WelcomeView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)
        
        router.viewController = viewController
        
        return viewController
    }
}
