import SwiftUI
import WalletConnectSign

final class SessionResponseModule {
    @discardableResult
    static func create(app: Application, sessionResponse: Response) -> UIViewController {
        let router = SessionResponseRouter(app: app)
        let presenter = SessionResponsePresenter(router: router, sessionResponse: sessionResponse)

        let view = NewPairingView().environmentObject(presenter)
        let viewController = UIHostingController(rootView: view)

        router.viewController = viewController

        return viewController
    }
}
