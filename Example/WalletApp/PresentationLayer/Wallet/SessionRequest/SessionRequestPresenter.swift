import UIKit
import Combine

import Web3Wallet

final class SessionRequestPresenter: ObservableObject {
    private let interactor: SessionRequestInteractor
    private let router: SessionRequestRouter
    
    let sessionRequest: Request
    
    var message: String {
        return String(describing: sessionRequest.params.value)
    }
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: SessionRequestInteractor,
        router: SessionRequestRouter,
        sessionRequest: Request
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.sessionRequest = sessionRequest
    }

    @MainActor
    func onApprove() async throws {
        try await interactor.approve(sessionRequest: sessionRequest)
        router.dismiss()
    }

    @MainActor
    func onReject() async throws {
        try await interactor.reject(sessionRequest: sessionRequest)
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
