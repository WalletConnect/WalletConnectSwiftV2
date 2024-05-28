import SwiftUI

final class ConfigModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = ConfigRouter(app: app)
        let presenter = ConfigPresenter(router: router)
        let view = ConfigView().environmentObject(presenter)

        let viewController = SceneViewController(viewModel: presenter, content: view)
        router.viewController = viewController

        return viewController
    }
}
