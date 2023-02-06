import SwiftUI

final class PushMessagesModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = PushMessagesRouter(app: app)
        let interactor = PushMessagesInteractor()
        let presenter = PushMessagesPresenter(interactor: interactor, router: router)
        let view = PushMessagesView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
