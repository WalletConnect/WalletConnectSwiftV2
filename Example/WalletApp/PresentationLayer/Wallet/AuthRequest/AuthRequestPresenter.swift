import UIKit
import Combine

import Web3Wallet

final class AuthRequestPresenter: ObservableObject {
    private let interactor: AuthRequestInteractor
    private let router: AuthRequestRouter
    
    let request: AuthRequest
    let verified: Bool?
    
    var message: String {
        return interactor.formatted(request: request)
    }
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: AuthRequestInteractor,
        router: AuthRequestRouter,
        request: AuthRequest,
        context: VerifyContext?
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.request = request
        self.verified = (context?.validation == .valid) ? true : (context?.validation == .unknown ? nil : false)
    }

    @MainActor
    func onApprove() async throws {
        try await interactor.approve(request: request)
        router.dismiss()
    }

    @MainActor
    func onReject() async throws {
        try await interactor.reject(request: request)
        router.dismiss()
    }
}

// MARK: - Private functions
private extension AuthRequestPresenter {
    func setupInitialState() {

    }
}

// MARK: - SceneViewModel
extension AuthRequestPresenter: SceneViewModel {

}
