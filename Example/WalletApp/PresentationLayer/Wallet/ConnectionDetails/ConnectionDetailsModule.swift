import SwiftUI

import Web3Wallet

final class ConnectionDetailsModule {
    @discardableResult
    static func create(app: Application, session: Session) -> UIViewController {
        let router = ConnectionDetailsRouter(app: app)
        let interactor = ConnectionDetailsInteractor()
        let presenter = ConnectionDetailsPresenter(
            interactor: interactor,
            router: router,
            session: session
        )
        let view = ConnectionDetailsView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
