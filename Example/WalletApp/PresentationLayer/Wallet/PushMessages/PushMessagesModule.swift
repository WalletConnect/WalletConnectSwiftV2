import SwiftUI
import WalletConnectPush

final class PushMessagesModule {

    @discardableResult
    static func create(app: Application, subscription: PushSubscription) -> UIViewController {
        let router = PushMessagesRouter(app: app)
        let interactor = PushMessagesInteractor(subscription: subscription)
        let presenter = PushMessagesPresenter(interactor: interactor, router: router)
        let view = PushMessagesView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
