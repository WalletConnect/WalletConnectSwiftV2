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
            ActivityIndicatorManager.shared.start()
            let showConnected = try await interactor.respondSessionRequest(sessionRequest: sessionRequest, importAccount: importAccount)
            showConnected ? showSignedSheet.toggle() : router.dismiss()
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
            try await interactor.respondError(sessionRequest: sessionRequest)
            ActivityIndicatorManager.shared.stop()
            router.dismiss()
        } catch {
            ActivityIndicatorManager.shared.stop()
            errorMessage = error.localizedDescription
            showError.toggle()
        }
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
    func setupInitialState() {
        Web3Wallet.instance.requestExpirationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requestId in
                guard let self = self else { return }
                if requestId == sessionRequest.id {
                    dismiss()
                }
            }.store(in: &disposeBag)
    }
}

// MARK: - SceneViewModel
extension SessionRequestPresenter: SceneViewModel {

}
