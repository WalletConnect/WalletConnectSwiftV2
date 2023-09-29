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
        return (decryptedMessage ?? "Failed to decrypt") ?? "Failed to decrypt"
    }
    
    @Published var showError = false
    @Published var errorMessage = "Error"
    
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
            try await interactor.approve(sessionRequest: sessionRequest, importAccount: importAccount)
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
    func setupInitialState() {}
    
    func hexToString(hexString: String) -> String {
        let regex = try! NSRegularExpression(pattern: "(0x)?([0-9A-Fa-f]{2})", options: .caseInsensitive)
        let textNS = hexString as NSString
        let matchesArray = regex.matches(in: textNS as String, options: [], range: NSMakeRange(0, textNS.length))
        let characters = matchesArray.map {
            Character(UnicodeScalar(UInt32(textNS.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }

        return String(characters)
    }
}

// MARK: - SceneViewModel
extension SessionRequestPresenter: SceneViewModel {

}
