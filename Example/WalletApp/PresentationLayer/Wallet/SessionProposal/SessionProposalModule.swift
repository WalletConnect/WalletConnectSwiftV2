import SwiftUI

import Web3Wallet

final class SessionProposalModule {

    @discardableResult
    static func create(
        app: Application,
        importAccount: ImportAccount,
        proposal: Session.Proposal,
        context: VerifyContext?
    ) -> UIViewController {
        let router = SessionProposalRouter(app: app)
        let interactor = SessionProposalInteractor()
        let presenter = SessionProposalPresenter(
            interactor: interactor,
            router: router,
            importAccount: importAccount,
            proposal: proposal,
            context: context
        )
        let view = SessionProposalView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)
        
        router.viewController = viewController
        
        return viewController
    }
}
