import SwiftUI

final class WelcomeModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = WelcomeRouter(app: app)
        let presenter = WelcomePresenter(router: router)
        let view = WelcomeView().environmentObject(presenter)
        let viewController = UIHostingController(rootView: view)

        router.viewController = viewController

        return viewController
    }

}
