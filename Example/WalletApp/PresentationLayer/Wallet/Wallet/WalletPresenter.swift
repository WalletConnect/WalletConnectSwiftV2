import UIKit
import Combine

import Web3Wallet

final class WalletPresenter: ObservableObject {
    enum Errors: Error {
        case invalidUri(uri: String)
    }
    
    private let interactor: WalletInteractor
    private let router: WalletRouter
    private let importAccount: ImportAccount
    
    private let app: Application
    
    @Published var sessions = [Session]()
    
    @Published var showPairingLoading = false
    @Published var showError = false
    @Published var errorMessage = "Error"
    @Published var showConnectedSheet = false
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: WalletInteractor,
        router: WalletRouter,
        app: Application,
        importAccount: ImportAccount
    ) {
        defer {
            setupInitialState()
        }
        self.interactor = interactor
        self.router = router
        self.app = app
        self.importAccount = importAccount
    }
    
    func onAppear() {
        showPairingLoading = app.requestSent
        showPairingLoading = false

        let pendingRequests = interactor.getPendingRequests()
        if let request = pendingRequests.first(where: { $0.context != nil }) {
            router.present(sessionRequest: request.request, importAccount: importAccount, sessionContext: request.context)
        }
    }
    
    func onConnection(session: Session) {
        router.presentConnectionDetails(session: session)
    }

    func onPasteUri() {
        router.presentPaste { [weak self] uri in
            guard let uri = WalletConnectURI(string: uri) else {
                self?.errorMessage = Errors.invalidUri(uri: uri).localizedDescription
                self?.showError.toggle()
                return
            }
            print("URI: \(uri)")
            self?.pair(uri: uri)

        } onError: { [weak self] error in
            print(error.localizedDescription)
            self?.router.dismiss()
        }
    }

    func onScanUri() {
        router.presentScan { [weak self] uri in
            guard let uri = WalletConnectURI(string: uri) else {
                self?.errorMessage = Errors.invalidUri(uri: uri).localizedDescription
                self?.showError.toggle()
                return
            }
            print("URI: \(uri)")
            self?.pair(uri: uri)
            self?.router.dismiss()
        } onError: { error in
            print(error.localizedDescription)
            self.router.dismiss()
        }
    }
    
    func removeSession(at indexSet: IndexSet) async {
        if let index = indexSet.first {
            try? await interactor.disconnectSession(session: sessions[index])
        }
    }
}

// MARK: - Private functions
extension WalletPresenter {
    private func setupInitialState() {
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
        Task.detached(priority: .high) { @MainActor [unowned self] in
            do {
                self.showPairingLoading = true
                self.setUpPairingIndicatorRemoval(topic: uri.topic)
                try await self.interactor.pair(uri: uri)
            } catch {
                self.showPairingLoading = false
                self.errorMessage = error.localizedDescription
                self.showError.toggle()
            }
        }
    }
    
    private func pairFromDapp() {
        guard let uri = app.uri else {
            return
        }
        pair(uri: uri)
    }

    private func setUpPairingIndicatorRemoval(topic: String) {
        Web3Wallet.instance.pairingExpirationPublisher.sink { pairing in
            guard pairing.topic == topic else {return}
            self.showPairingLoading = false
        }.store(in: &disposeBag)

        Web3Wallet.instance.sessionRequestPublisher.sink { _ in
            self.showPairingLoading = false
        }.store(in: &disposeBag)
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

// MARK: - LocalizedError
extension WalletPresenter.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUri(let uri):  return "URI invalid format\n\(uri)"
        }
    }
}
