import Combine
import Auth
import WalletConnectPairing

protocol WalletInteractorProtocol {
    func onAppear()
    func pastePairingUri() async
    func scanPairingUri()
}

final class WalletInteractor: WalletInteractorProtocol {
    private var disposeBag = Set<AnyCancellable>()
    
    private weak var presenter: WalletPresenter?
    private let router: WalletRouter
    
    private var requestPublisher: AnyPublisher<AuthRequest, Never> {
        return Auth.instance.authRequestPublisher
    }
    
    init(
        presenter: WalletPresenter,
        router: WalletRouter
    ) {
        self.presenter = presenter
        self.router = router
    }
    
    func onAppear() {
        requestPublisher.sink { [weak self] request in
            self?.router.present(request: request)
        }.store(in: &disposeBag)
    }

    func pastePairingUri() async {
        guard let string = UIPasteboardWrapper.string,
              let uri = WalletConnectURI(string: string)
        else {
            return
        }
        try? await pair(uri: uri)
    }
    
    func scanPairingUri() {
        router.presentScan { [weak self] value in
            guard let self,
                  let uri = WalletConnectURI(string: value) else {
                return
            }
            
            Task {
                try? await self.pair(uri: uri)
            }
            self.router.dismiss()
        } onError: { [weak self] error in
            print(error.localizedDescription)
            self?.router.dismiss()
        }
    }
}

// MARK: - Private functions
extension WalletInteractor {
    private func pair(uri: WalletConnectURI) async throws {
        try await Pair.instance.pair(uri: uri)
    }
}
