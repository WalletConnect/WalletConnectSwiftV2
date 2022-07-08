import SwiftUI

final class ChatModule {

    @discardableResult
    static func create(topic: String, app: Application) -> UIViewController {
        let router = ChatRouter(app: app)
        let interactor = ChatInteractor(chatService: app.chatService)
        let presenter = ChatPresenter(topic: topic, interactor: interactor, router: router)
        let view = ChatView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
