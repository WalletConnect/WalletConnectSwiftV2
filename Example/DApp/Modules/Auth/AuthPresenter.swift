import UIKit
import Combine
import WalletConnectSign


final class AuthPresenter: ObservableObject {
    enum SigningState {
        case none
        case signed(Session)
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
        Sign.instance.authResponsePublisher.sink { [weak self] (_, result) in
            switch result {
            case .success(let session):
                self?.signingState = .signed(session)
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
            let uri = try await Sign.instance.authenticate(.stub())
            walletConnectUri = uri
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
extension AuthRequestParams {
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
    ) -> AuthRequestParams {
        return AuthRequestParams(
            domain: domain,
            chains: [chainId],
            nonce: nonce,
            aud: aud,
            nbf: nbf,
            exp: exp,
            statement: statement,
            requestId: requestId,
            resources: resources,
            methods: ["eth_sign", "personal_sign", "eth_signTypedData"]
        )
    }
}

