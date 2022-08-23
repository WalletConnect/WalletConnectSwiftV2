import SwiftUI

final class WelcomeModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = WelcomeRouter(app: app)
        let interactor = WelcomeInteractor(chatService: app.chatService, accountStorage: app.accountStorage)
        let presenter = WelcomePresenter(router: router, interactor: interactor)
        let view = WelcomeView().environmentObject(presenter)
        let viewController = UIHostingController(rootView: view)

        router.viewController = viewController

        return viewController
    }

}
