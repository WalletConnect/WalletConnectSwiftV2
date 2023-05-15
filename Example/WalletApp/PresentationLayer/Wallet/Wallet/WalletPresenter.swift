import UIKit
import Combine

import Web3Wallet

final class WalletPresenter: ObservableObject {
    enum Errors: Error {
        case invalidUri(uri: String)
    }
    
    private let interactor: WalletInteractor
    private let router: WalletRouter
    
    private let uri: String?
    
    @Published var sessions = [Session]()
    
    @Published var showError = false
    @Published var errorMessage = "Error"
    
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
}

// MARK: - Private functions
extension WalletPresenter {
    private func setupInitialState() {
        interactor.requestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.router.present(request: result.request, context: result.context)
            }
            .store(in: &disposeBag)
        
        interactor.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] request, context in
                self?.router.present(sessionRequest: request, sessionContext: context)
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
            do {
                try await self.interactor.pair(uri: uri)
            } catch {
                Task.detached { @MainActor in
                    self.errorMessage = error.localizedDescription
                    self.showError.toggle()
                }
            }
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

// MARK: - LocalizedError
extension WalletPresenter.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUri(let uri):  return "URI invalid format\n\(uri)"
        }
    }
}
