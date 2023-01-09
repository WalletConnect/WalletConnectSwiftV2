import UIKit
import Combine

import Web3Wallet

final class SessionRequestPresenter: ObservableObject {
    private let interactor: SessionRequestInteractor
    private let router: SessionRequestRouter
    
    let proposal: Proposal
    private let sessionProposal: Session.Proposal
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: SessionRequestInteractor,
        router: SessionRequestRouter,
        proposal: Session.Proposal
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.proposal = Proposal(proposal: proposal)
        self.sessionProposal = proposal
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
private extension SessionRequestPresenter {
    func setupInitialState() {

    }
}

// MARK: - SceneViewModel
extension SessionRequestPresenter: SceneViewModel {

}
