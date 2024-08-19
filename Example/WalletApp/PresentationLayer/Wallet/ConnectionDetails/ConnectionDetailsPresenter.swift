import UIKit
import Combine

import Web3Wallet

final class ConnectionDetailsPresenter: ObservableObject {
    private let router: ConnectionDetailsRouter
    
    let session: Session
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        router: ConnectionDetailsRouter,
        session: Session
    ) {
        self.router = router
        self.session = session
    }

    func onDelete() {
        Task {
            do {
                ActivityIndicatorManager.shared.start()
                try await Web3Wallet.instance.disconnect(topic: session.topic)
                ActivityIndicatorManager.shared.stop()
                DispatchQueue.main.async {
                    self.router.dismiss()
                }
            } catch {
                ActivityIndicatorManager.shared.stop()
                print(error)
            }
        }
    }


    func accountReferences(namespace: String) -> [String] {
        session.namespaces[namespace]?.accounts.map { "\($0.namespace):\(($0.reference))" } ?? []
    }


    func createUpdatedSessionNamespaces(existingNamespaces: [String: SessionNamespace]) -> [String: SessionNamespace] {
        // Define the Arbitrum chain identifier
        let arbitrumChainIdentifier = "eip155:1"
        let arbitrumChain = Blockchain(arbitrumChainIdentifier)!

        var updatedNamespaces = existingNamespaces

        for (key, namespace) in existingNamespaces {
            // Use the address of the first account in the namespace
            let newAccountAddress = namespace.accounts.first!.address
            let newAccount = Account(chainIdentifier: arbitrumChainIdentifier, address: newAccountAddress)!

            var updatedChains = namespace.chains ?? []
            var updatedAccounts = namespace.accounts

            // Ensure Arbitrum chain is at the first position
            if let index = updatedChains.firstIndex(of: arbitrumChain) {
                updatedChains.remove(at: index)
            }
            updatedChains.insert(arbitrumChain, at: 0)

            // Ensure the new account for Arbitrum is at the first position
            if let index = updatedAccounts.firstIndex(of: newAccount) {
                updatedAccounts.remove(at: index)
            }
            updatedAccounts.insert(newAccount, at: 0)

            // Update the session namespace with the modified chains and accounts
            let updatedNamespace = SessionNamespace(chains: updatedChains, accounts: updatedAccounts, methods: namespace.methods, events: namespace.events)
            updatedNamespaces[key] = updatedNamespace
        }

        return updatedNamespaces
    }

    func onUpdate() {
        Task {
            do {
                ActivityIndicatorManager.shared.start()

                let existingNamespaces = session.namespaces

                let updatedNamespaces = createUpdatedSessionNamespaces(existingNamespaces: existingNamespaces)

                try await Web3Wallet.instance.update(topic: session.topic, namespaces: updatedNamespaces)

                ActivityIndicatorManager.shared.stop()
                DispatchQueue.main.async {
                    self.router.dismiss()
                }
            } catch {
                ActivityIndicatorManager.shared.stop()
                print(error)
            }
        }
    }
}

// MARK: - Private functions
private extension ConnectionDetailsPresenter {

}

// MARK: - SceneViewModel
extension ConnectionDetailsPresenter: SceneViewModel {

}
