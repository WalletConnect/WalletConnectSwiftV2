import UIKit
import Combine

import Web3Wallet

final class WalletPresenter: ObservableObject {
    private let interactor: WalletInteractor
    private let router: WalletRouter
    
    @Published var sessions = [Session]()
    
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
    
    func onConnection(session: Session) {
        router.presentConnectionDetails(session: session)
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
        interactor.requestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] request in
                self?.router.present(request: request)
            }
            .store(in: &disposeBag)
        
        interactor.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                self?.router.present(sessionRequest: sessionRequest)
            }.store(in: &disposeBag)

        interactor.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                self?.sessions = sessions
            }
            .store(in: &disposeBag)
        
        sessions = interactor.getSessions()
        
        pairFromDapp()
    }

    private func pair(uri: WalletConnectURI) {
        Task(priority: .high) { [unowned self] in
            try await self.interactor.pair(uri: uri)
        }
    }
    
    private func pairFromDapp() {
        guard let uri = uri,
              let walletConnectUri = WalletConnectURI(string: uri)
        else {
            return
        }
        pair(uri: walletConnectUri)
    }
    
    func removeSession(at indexSet: IndexSet) async {
        if let index = indexSet.first {
            try? await interactor.disconnectSession(session: sessions[index])
        }
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
