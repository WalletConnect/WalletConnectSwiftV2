import SwiftUI

final class WalletModule {
    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = WalletRouter(app: app)
        let presenter = WalletPresenter()
        let interactor = WalletInteractor(presenter: presenter, router: router)
        let view = WalletView(interactor: interactor, presenter: presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
