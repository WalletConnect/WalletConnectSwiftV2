import SwiftUI
import WalletConnectNotify

final class SubscriptionModule {

    @discardableResult
    static func create(app: Application, subscription: NotifySubscription) -> UIViewController {
        let router = SubscriptionRouter(app: app)
        let interactor = SubscriptionInteractor(subscription: subscription)
        let presenter = SubscriptionPresenter(subscription: subscription, interactor: interactor, router: router)
        let view = SubscriptionView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
