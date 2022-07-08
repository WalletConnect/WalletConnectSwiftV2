import SwiftUI

final class ChatListModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = ChatListRouter(app: app)
        let interactor = ChatListInteractor(chatService: app.chatService)
        let presenter = ChatListPresenter(interactor: interactor, router: router)
        let view = ChatListView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
