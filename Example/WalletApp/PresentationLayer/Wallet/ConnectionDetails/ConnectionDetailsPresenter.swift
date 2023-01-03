import UIKit
import Combine

import Auth
import Web3Wallet

final class ConnectionDetailsPresenter: ObservableObject {
    private let interactor: ConnectionDetailsInteractor
    private let router: ConnectionDetailsRouter
    
    let session: Session
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: ConnectionDetailsInteractor,
        router: ConnectionDetailsRouter,
        session: Session
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.session = session
    }

    func didPastePairingURI() {
        guard let string = UIPasteboard.general.string, let uri = WalletConnectURI(string: string) else { return }
        print(uri)
        pair(uri: uri)
    }

    func didScanPairingURI() {
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
private extension ConnectionDetailsPresenter {
    func setupInitialState() {
        interactor.requestPublisher.sink { [unowned self] request in
            self.router.present(request: request)
        }.store(in: &disposeBag)
    }

    func pair(uri: WalletConnectURI) {
        Task(priority: .high) { [unowned self] in
            try await self.interactor.pair(uri: uri)
        }
    }
}

// MARK: - SceneViewModel
extension ConnectionDetailsPresenter: SceneViewModel {

}
