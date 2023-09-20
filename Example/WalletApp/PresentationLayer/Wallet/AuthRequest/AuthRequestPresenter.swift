import UIKit
import Combine

import Web3Wallet

final class AuthRequestPresenter: ObservableObject {
    private let interactor: AuthRequestInteractor
    private let router: AuthRequestRouter

    let importAccount: ImportAccount
    let request: AuthRequest
    let validationStatus: VerifyContext.ValidationStatus?
    
    var message: String {
        return interactor.formatted(request: request, account: importAccount.account)
    }
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        importAccount: ImportAccount,
        interactor: AuthRequestInteractor,
        router: AuthRequestRouter,
        request: AuthRequest,
        context: VerifyContext?
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.importAccount = importAccount
        self.request = request
        self.validationStatus = context?.validation
    }

    @MainActor
    func onApprove() async throws {
        try await interactor.approve(request: request, importAccount: importAccount)
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
