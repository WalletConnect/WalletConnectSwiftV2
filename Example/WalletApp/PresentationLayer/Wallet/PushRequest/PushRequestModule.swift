import SwiftUI
import WalletConnectPush

final class PushRequestModule {
    @discardableResult
    static func create(app: Application, pushRequest: PushRequest) -> UIViewController {
        let router = SessionRequestRouter(app: app)
        let interactor = SessionRequestInteractor()
        let presenter = SessionRequestPresenter(interactor: interactor, router: router, sessionRequest: sessionRequest)
        let view = SessionRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
