import UIKit
import Combine

import Web3Wallet

final class SessionRequestPresenter: ObservableObject {
    private let interactor: SessionRequestInteractor
    private let router: SessionRequestRouter
    private let importAccount: ImportAccount
    
    let sessionRequest: Request
    let session: Session?
    let validationStatus: VerifyContext.ValidationStatus?
    
    var message: String {
        let message = try? sessionRequest.params.get([String].self)
        let decryptedMessage = message.map { String(data: Data(hex: $0.first ?? ""), encoding: .utf8) }
        return (decryptedMessage ?? String(describing: sessionRequest.params.value)) ?? String(describing: sessionRequest.params.value)
    }
    
    @Published var showError = false
    @Published var errorMessage = "Error"
    @Published var showSignedSheet = false
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: SessionRequestInteractor,
        router: SessionRequestRouter,
        sessionRequest: Request,
        importAccount: ImportAccount,
        context: VerifyContext?
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.sessionRequest = sessionRequest
        self.session = interactor.getSession(topic: sessionRequest.topic)
        self.importAccount = importAccount
        self.validationStatus = context?.validation
    }

    @MainActor
    func onApprove() async throws {
        do {
            let showConnected = try await interactor.approve(sessionRequest: sessionRequest, importAccount: importAccount)
            showConnected ? showSignedSheet.toggle() : router.dismiss()
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
    
    func onSignedSheetDismiss() {
        dismiss()
    }
    
    func dismiss() {
        router.dismiss()
    }
}

// MARK: - Private functions
private extension SessionRequestPresenter {
    func setupInitialState() {}
}

// MARK: - SceneViewModel
extension SessionRequestPresenter: SceneViewModel {

}
