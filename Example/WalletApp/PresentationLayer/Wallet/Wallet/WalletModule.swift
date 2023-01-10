import SwiftUI

final class WalletModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = WalletRouter(app: app)
        let interactor = WalletInteractor()
        let presenter = WalletPresenter(interactor: interactor, router: router, uri: app.uri)
        let view = WalletView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
