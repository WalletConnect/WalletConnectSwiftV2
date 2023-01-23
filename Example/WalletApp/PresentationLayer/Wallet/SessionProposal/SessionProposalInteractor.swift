import Foundation

import Web3Wallet

final class SessionProposalInteractor {
    lazy var accounts = [
        "eip155": ETHSigner.address,
        "solana": SOLSigner.address
    ]

    func approve(proposal: Session.Proposal) async throws {
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(self.accounts[$0.namespace]!)") })

            let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        
        try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }

    func reject(proposal: Session.Proposal) async throws {
        try await Web3Wallet.instance.reject(proposalId: proposal.id, reason: .userRejected)
    }
}
