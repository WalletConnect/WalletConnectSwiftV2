import SwiftUI
import WalletConnectPush

final class PushRequestModule {
    @discardableResult
    static func create(app: Application, pushRequest: PushRequest) -> UIViewController {
        let router = PushRequestRouter(app: app)
        let interactor = PushRequestInteractor()
        let presenter = PushRequestPresenter(interactor: interactor, router: router, pushRequest: pushRequest)
        let view = PushRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
