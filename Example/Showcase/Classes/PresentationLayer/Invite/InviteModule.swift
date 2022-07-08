import SwiftUI

final class InviteModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = InviteRouter(app: app)
        let interactor = InviteInteractor()
        let presenter = InvitePresenter(interactor: interactor, router: router)
        let view = InviteView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
