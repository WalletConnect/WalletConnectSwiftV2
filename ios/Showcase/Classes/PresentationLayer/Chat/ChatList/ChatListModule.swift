import SwiftUI

final class ChatListModule {

    @discardableResult
    static func create(app: Application, account: Account) -> UIViewController {
        let router = ChatListRouter(app: app)
        let interactor = ChatListInteractor(chatService: app.chatService, accountStorage: app.accountStorage)
        let presenter = ChatListPresenter(account: account, interactor: interactor, router: router)
        let view = ChatListView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
