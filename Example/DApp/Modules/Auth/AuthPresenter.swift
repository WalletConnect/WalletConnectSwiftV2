import UIKit
import Combine

import Auth

final class AuthPresenter: ObservableObject {
    enum SigningState {
        case none
        case signed(Cacao)
        case error(Error)
    }
    
    private let interactor: AuthInteractor
    private let router: AuthRouter

    @Published var qrCodeImageData: Data?
    @Published var signingState = SigningState.none
    @Published var showSigningState = false
    
    private var walletConnectUri: WalletConnectURI?
    
    private var subscriptions = Set<AnyCancellable>()

    init(
        interactor: AuthInteractor,
        router: AuthRouter
    ) {
        defer {
            Task {
                await setupInitialState()
            }
        }
        self.interactor = interactor
        self.router = router
    }
    
    func onAppear() {
        generateQR()
    }
    
    func copyUri() {
        UIPasteboard.general.string = walletConnectUri?.absoluteString
    }
    
    func connectWallet() {
        if let walletConnectUri {
            let walletUri = URL(string: "walletapp://wc?uri=\(walletConnectUri.deeplinkUri.removingPercentEncoding!)")!
            DispatchQueue.main.async {
                UIApplication.shared.open(walletUri)
            }
        }
    }
}

// MARK: - Private functions
extension AuthPresenter {
    @MainActor
    private func setupInitialState() {
        Auth.instance.authResponsePublisher.sink { [weak self] (_, result) in
            switch result {
            case .success(let cacao): 
                self?.signingState = .signed(cacao)
                self?.generateQR()
                self?.showSigningState.toggle()
                
            case .failure(let error): 
                self?.signingState = .error(error)
                self?.showSigningState.toggle()
            }
        }
        .store(in: &subscriptions)
    }
    
    private func generateQR() {
        Task { @MainActor in
            let uri = try! await Pair.instance.create()
            walletConnectUri = uri
            try await Auth.instance.request(.stub(), topic: uri.topic)
            let qrCodeImage = QRCodeGenerator.generateQRCode(from: uri.absoluteString)
            DispatchQueue.main.async {
                self.qrCodeImageData = qrCodeImage.pngData()
            }
        }
    }
}

// MARK: - SceneViewModel
extension AuthPresenter: SceneViewModel {}

// MARK: - Auth request stub
private extension RequestParams {
    static func stub(
        domain: String = "service.invalid",
        chainId: String = "eip155:1",
        nonce: String = "32891756",
        aud: String = "https://service.invalid/login",
        nbf: String? = nil,
        exp: String? = nil,
        statement: String? = "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
        requestId: String? = nil,
        resources: [String]? = ["ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/", "https://example.com/my-web2-claim.json"]
    ) -> RequestParams {
        return RequestParams(
            domain: domain,
            chainId: chainId,
            nonce: nonce,
            aud: aud,
            nbf: nbf,
            exp: exp,
            statement: statement,
            requestId: requestId,
            resources: resources
        )
    }
}

