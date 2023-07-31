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
    @Published var networkConnected = true
    @Published var socketConnected = false
    
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
        
        interactor.web3WalletStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .idle:
                    print("IDLE")
                    
                case .pairing:
                    print("STATE SHOW")
                    self?.showPairingLoading = true
                    
                case .received:
                    print("STATE HIDE")
                    self?.showPairingLoading = false
                    
                case .pairingTimeout:
                    self?.showPairingLoading = false
                    self?.errorMessage = "WalletConnect - Pairing timeout error"
                    self?.showError.toggle()
                    
                case .networkConnected:
                    self?.networkConnected = true
                    
                case .networkDisconnected:
                    self?.networkConnected = false
                }
            }
            .store(in: &disposeBag)
        
        interactor.socketConnectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .connected:    self?.socketConnected = true
                case .disconnected: self?.socketConnected = false
                }
            }
            .store(in: &disposeBag)
    }
    
    func onConnection(session: Session) {
        router.presentConnectionDetails(session: session)
    }

    func onPasteUri() {
        router.presentPaste { [weak self] uri in
            guard let uri = WalletConnectURI(string: uri) else {
                self?.showPairingLoading = false
                self?.errorMessage = Errors.invalidUri(uri: uri).localizedDescription
                self?.showError.toggle()
                return
            }
            print("URI: \(uri)")
            self?.pair(uri: uri)

        } onError: { [weak self] error in
            print(error.localizedDescription)
            self?.showPairingLoading = false
            self?.router.dismiss()
        }
    }

    func onScanUri() {
        router.presentScan { [weak self] uri in
            guard let uri = WalletConnectURI(string: uri) else {
                self?.showPairingLoading = false
                self?.errorMessage = Errors.invalidUri(uri: uri).localizedDescription
                self?.showError.toggle()
                return
            }
            print("URI: \(uri)")
            self?.pair(uri: uri)
            self?.router.dismiss()
        } onError: { [weak self] error in
            print(error.localizedDescription)
            self?.showPairingLoading = false
            self?.router.dismiss()
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
        interactor.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] session in
                router.present(proposal: session.proposal, importAccount: importAccount, context: session.context)
            }
            .store(in: &disposeBag)
        
        interactor.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] request, context in
                router.present(sessionRequest: request, importAccount: importAccount, sessionContext: context)
            }.store(in: &disposeBag)
        
        interactor.requestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] result in
                router.present(request: result.request, importAccount: importAccount, context: result.context)
            }
            .store(in: &disposeBag)

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
                try await self.interactor.pair(uri: uri)
            } catch {
                self.showPairingLoading = false
                self.errorMessage = error.localizedDescription
                self.showError.toggle()
            }
        }
    }
    
    private func pairFromDapp() {
        guard let uri = app.uri,
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

// MARK: - LocalizedError
extension WalletPresenter.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUri(let uri):  return "URI invalid format\n\(uri)"
        }
    }
}
