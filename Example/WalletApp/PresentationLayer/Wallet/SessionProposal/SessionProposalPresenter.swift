import UIKit
import Combine

import Web3Wallet

final class SessionProposalPresenter: ObservableObject {
    private let interactor: SessionProposalInteractor
    private let router: SessionProposalRouter
    
    let sessionProposal: Session.Proposal
    let verified: Bool?
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: SessionProposalInteractor,
        router: SessionProposalRouter,
        proposal: Session.Proposal,
        context: VerifyContext?
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.sessionProposal = proposal
        self.verified = (context?.validation == .valid) ? true : (context?.validation == .unknown ? nil : false)
    }
    
    @MainActor
    func onApprove() async throws {
        try await interactor.approve(proposal: sessionProposal)
        router.dismiss()
    }

    @MainActor
    func onReject() async throws {
        try await interactor.reject(proposal: sessionProposal)
        router.dismiss()
    }
}

// MARK: - Private functions
private extension SessionProposalPresenter {
    func setupInitialState() {

    }
}

// MARK: - SceneViewModel
extension SessionProposalPresenter: SceneViewModel {

}
