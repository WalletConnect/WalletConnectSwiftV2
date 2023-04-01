import SwiftUI

final class InviteListModule {

    @discardableResult
    static func create(app: Application, account: Account, type: InviteType) -> UIViewController {
        let router = InviteListRouter(app: app)
        let interactor = InviteListInteractor(chatService: app.chatService)
        let presenter = InviteListPresenter(interactor: interactor, router: router, account: account, inviteType: type)
        let view = InviteListView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
