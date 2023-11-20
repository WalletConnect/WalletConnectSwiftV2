import SwiftUI

import WalletConnectSign

final class SessionAccountModule {
    @discardableResult
    static func create(app: Application, sessionAccount: AccountDetails, session: Session) -> UIViewController {
        let router = SessionAccountRouter(app: app)
        let interactor = SessionAccountInteractor()
        let presenter = SessionAccountPresenter(interactor: interactor, router: router, sessionAccount: sessionAccount, session: session)
        let view = SessionAccountView().environmentObject(presenter)
        let viewController = UIHostingController(rootView: view)

        router.viewController = viewController

        return viewController
    }
}
