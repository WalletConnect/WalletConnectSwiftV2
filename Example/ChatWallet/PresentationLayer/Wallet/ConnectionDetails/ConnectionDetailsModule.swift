import SwiftUI

final class ConnectionDetailsModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = ConnectionDetailsRouter(app: app)
        let interactor = ConnectionDetailsInteractor()
        let presenter = ConnectionDetailsPresenter(interactor: interactor, router: router)
        let view = ConnectionDetailsView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
