import UIKit
import Combine
import Auth

final class WalletPresenter: ObservableObject {
    private let interactor: WalletInteractor
    private let router: WalletRouter
    
    private let uri: String?
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: WalletInteractor,
        router: WalletRouter,
        uri: String?
    ) {
        defer {
            setupInitialState()
        }
        self.interactor = interactor
        self.router = router
        self.uri = uri
    }
    
    func onConnection() {
        router.presentConnectionDetails()
    }

    func onPasteUri() {
        router.presentPaste { [weak self] uri in
            guard let uri = WalletConnectURI(string: uri) else {
                return
            }
            print(uri)
            self?.pair(uri: uri)

        } onError: { [weak self] error in
            print(error.localizedDescription)
            self?.router.dismiss()
        }
    }

    func onScanUri() {
        router.presentScan { [unowned self] value in
            guard let uri = WalletConnectURI(string: value) else { return }
            self.pair(uri: uri)
            self.router.dismiss()
        } onError: { error in
            print(error.localizedDescription)
            self.router.dismiss()
        }
    }
}

// MARK: - Private functions
extension WalletPresenter {
    private func setupInitialState() {
        interactor.requestPublisher.sink { [unowned self] request in
            self.router.present(request: request)
        }.store(in: &disposeBag)
        
        pairFropDapp()
    }

    private func pair(uri: WalletConnectURI) {
        Task(priority: .high) { [unowned self] in
            try await self.interactor.pair(uri: uri)
        }
    }
    
    private func pairFropDapp() {
        guard let uri = uri,
              let walletConnectUri = WalletConnectURI(string: uri)
        else {
            return
        }
        pair(uri: walletConnectUri)
    }
}

// MARK: - SceneViewModel
extension WalletPresenter: SceneViewModel {
    var sceneTitle: String? {
        return "Connections"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}
