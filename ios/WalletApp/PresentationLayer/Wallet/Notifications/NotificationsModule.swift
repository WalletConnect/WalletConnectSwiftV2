import SwiftUI

final class NotificationsModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = NotificationsRouter(app: app)
        let interactor = NotificationsInteractor()
        let presenter = NotificationsPresenter(interactor: interactor, router: router)
        let view = NotificationsView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
