import SwiftUI

import Web3Wallet

final class SessionRequestModule {
    @discardableResult
    static func create(app: Application, proposal: Session.Proposal) -> UIViewController {
        let router = SessionRequestRouter(app: app)
        let interactor = SessionRequestInteractor()
        let presenter = SessionRequestPresenter(
            interactor: interactor,
            router: router,
            proposal: proposal
        )
        let view = SessionRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)
        
        router.viewController = viewController
        
        return viewController
    }
}
