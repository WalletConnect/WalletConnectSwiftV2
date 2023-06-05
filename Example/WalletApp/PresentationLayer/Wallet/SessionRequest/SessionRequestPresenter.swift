import UIKit
import Combine

import Web3Wallet

final class SessionRequestPresenter: ObservableObject {
    private let interactor: SessionRequestInteractor
    private let router: SessionRequestRouter
    
    let sessionRequest: Request
    let verified: Bool?
    
    var message: String {
        return String(describing: sessionRequest.params.value)
    }
    
    @Published var showError = false
    @Published var errorMessage = "Error"
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: SessionRequestInteractor,
        router: SessionRequestRouter,
        sessionRequest: Request,
        context: VerifyContext?
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.sessionRequest = sessionRequest
        self.verified = (context?.validation == .valid) ? true : (context?.validation == .unknown ? nil : false)
    }

    @MainActor
    func onApprove() async throws {
        do {
            try await interactor.approve(sessionRequest: sessionRequest)
            router.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError.toggle()
        }
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
