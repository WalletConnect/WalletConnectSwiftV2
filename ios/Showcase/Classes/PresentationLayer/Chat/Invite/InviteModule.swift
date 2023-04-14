import SwiftUI

final class InviteModule {

    @discardableResult
    static func create(app: Application, account: Account) -> UIViewController {
        let router = InviteRouter(app: app)
        let interactor = InviteInteractor(accountStorage: app.accountStorage, chatService: app.chatService)
        let presenter = InvitePresenter(interactor: interactor, router: router, account: account)
        let view = InviteView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
