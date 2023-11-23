import UIKit
import Combine

import Web3Modal
import WalletConnectSign

final class SignPresenter: ObservableObject {
    @Published var accountsDetails = [AccountDetails]()
    
    @Published var showError = false
    @Published var errorMessage = String.empty
    
    var walletConnectUri: WalletConnectURI?
    
    let chains = [
        Chain(name: "Ethereum", id: "eip155:1"),
        Chain(name: "Polygon", id: "eip155:137"),
        Chain(name: "Solana", id: "solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")
    ]
    
    private let interactor: SignInteractor
    private let router: SignRouter

    private var session: Session?
    
    private var subscriptions = Set<AnyCancellable>()

    init(
        interactor: SignInteractor,
        router: SignRouter
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }
    
    func onAppear() {
        
    }
    
    func copyUri() {
        UIPasteboard.general.string = walletConnectUri?.absoluteString
    }
    
    func connectWalletWithW3M() {
        Task {
            Web3Modal.set(sessionParams: .init(
                requiredNamespaces: Proposal.requiredNamespaces,
                optionalNamespaces: Proposal.optionalNamespaces
            ))
        }
        Web3Modal.present(from: nil)
    }
    
    @MainActor
    func connectWalletWithSign() {
        Task {
            let uri = try await Pair.instance.create()
            walletConnectUri = uri
            try await Sign.instance.connect(
                requiredNamespaces: Proposal.requiredNamespaces,
                optionalNamespaces: Proposal.optionalNamespaces,
                topic: uri.topic
            )
            router.presentNewPairing(walletConnectUri: uri)
        }
    }
    
    func disconnect() {
        if let session {
            Task { @MainActor in
                do {
                    try await Sign.instance.disconnect(topic: session.topic)
                    accountsDetails.removeAll()
                } catch {
                    showError.toggle()
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func presentSessionAccount(sessionAccount: AccountDetails) {
        if let session {
            router.presentSessionAccount(sessionAccount: sessionAccount, session: session)
        }
    }
}

// MARK: - Private functions
extension SignPresenter {
    private func setupInitialState() {
        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.router.dismiss()
                self.getSession()
            }
            .store(in: &subscriptions)
        
        getSession()
        
        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.accountsDetails.removeAll()
            }
            .store(in: &subscriptions)
    }
    
    private func getSession() {
        if let session = Sign.instance.getSessions().first {
            self.session = session
            session.namespaces.values.forEach { namespace in
                namespace.accounts.forEach { account in
                    accountsDetails.append(
                        AccountDetails(
                            chain: account.blockchainIdentifier,
                            methods: Array(namespace.methods),
                            account: account.address
                        )
                    )
                }
            }
        }
    }
}

// MARK: - SceneViewModel
extension SignPresenter: SceneViewModel {}
