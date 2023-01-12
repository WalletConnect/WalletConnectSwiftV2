import SwiftUI

import Web3Wallet

final class SessionProposalModule {
    @discardableResult
    static func create(app: Application, proposal: Session.Proposal) -> UIViewController {
        let router = SessionProposalRouter(app: app)
        let interactor = SessionProposalInteractor()
        let presenter = SessionProposalPresenter(
            interactor: interactor,
            router: router,
            proposal: proposal
        )
        let view = SessionProposalView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)
        
        router.viewController = viewController
        
        return viewController
    }
}
