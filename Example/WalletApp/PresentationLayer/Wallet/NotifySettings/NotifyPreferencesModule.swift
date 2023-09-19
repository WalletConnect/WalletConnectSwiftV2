import SwiftUI
import WalletConnectNotify

final class NotifyPreferencesModule {

    @discardableResult
    static func create(app: Application, subscription: NotifySubscription) -> UIViewController {
        let router = NotifyPreferencesRouter(app: app)
        let interactor = NotifyPreferencesInteractor()
        let presenter = NotifyPreferencesPresenter(subscription: subscription, interactor: interactor, router: router)
        let view = NotifyPreferencesView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
