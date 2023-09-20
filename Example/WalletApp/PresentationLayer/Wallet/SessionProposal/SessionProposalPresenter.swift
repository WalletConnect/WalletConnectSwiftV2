import UIKit
import Combine

import Web3Wallet

final class SessionProposalPresenter: ObservableObject {
    private let interactor: SessionProposalInteractor
    private let router: SessionProposalRouter

    let importAccount: ImportAccount
    let sessionProposal: Session.Proposal
    let validationStatus: VerifyContext.ValidationStatus?
    
    @Published var showError = false
    @Published var errorMessage = "Error"
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: SessionProposalInteractor,
        router: SessionProposalRouter,
        importAccount: ImportAccount,
        proposal: Session.Proposal,
        context: VerifyContext?
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.sessionProposal = proposal
        self.importAccount = importAccount
        self.validationStatus = context?.validation
    }
    
    @MainActor
    func onApprove() async throws {
        do {
            try await interactor.approve(proposal: sessionProposal, account: importAccount.account)
            router.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }

    @MainActor
    func onReject() async throws {
        do {
            try await interactor.reject(proposal: sessionProposal)
            router.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError.toggle()
        }
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
