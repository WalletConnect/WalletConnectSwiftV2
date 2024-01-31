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
    @Published var showConnectedSheet = false
    
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
            ActivityIndicatorManager.shared.start()
            let showConnected = try await interactor.approve(proposal: sessionProposal, account: importAccount.account)
            showConnected ? showConnectedSheet.toggle() : router.dismiss()
            ActivityIndicatorManager.shared.stop()
        } catch {
            ActivityIndicatorManager.shared.stop()
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }

    @MainActor
    func onReject() async throws {
        do {
            ActivityIndicatorManager.shared.start()
            try await interactor.reject(proposal: sessionProposal)
            ActivityIndicatorManager.shared.stop()
            router.dismiss()
        } catch {
            ActivityIndicatorManager.shared.stop()
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
    
    func onConnectedSheetDismiss() {
        router.dismiss()
    }

    func dismiss() {
        router.dismiss()
    }
}

// MARK: - Private functions
private extension SessionProposalPresenter {
    func setupInitialState() {
        Web3Wallet.instance.sessionProposalExpirationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] proposal in
            guard let self = self else { return }
            if proposal.id == self.sessionProposal.id {
                dismiss()
            }
        }.store(in: &disposeBag)

        Web3Wallet.instance.pairingExpirationPublisher
            .receive(on: DispatchQueue.main)
            .sink {[weak self]  pairing in
                if self?.sessionProposal.pairingTopic == pairing.topic {
                    self?.dismiss()
                }
        }.store(in: &disposeBag)
    }
}

// MARK: - SceneViewModel
extension SessionProposalPresenter: SceneViewModel {

}
