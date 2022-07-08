import SwiftUI

final class InviteListModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = InviteListRouter(app: app)
        let interactor = InviteListInteractor(chatService: app.chatService)
        let presenter = InviteListPresenter(interactor: interactor, router: router)
        let view = InviteListView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
