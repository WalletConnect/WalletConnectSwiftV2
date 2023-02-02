import Foundation

import Web3Wallet

final class SessionProposalInteractor {
    lazy var accounts = [
        "eip155": ETHSigner.address,
        "solana": SOLSigner.address
    ]

    func approve(proposal: Session.Proposal) async throws {
        var sessionNamespaces = [String: SessionNamespace]()
        makeSessionNamespaces(namespaces: proposal.requiredNamespaces, sessionNamespaces: &sessionNamespaces)
        proposal.optionalNamespaces.flatMap { makeSessionNamespaces(namespaces: $0, sessionNamespaces: &sessionNamespaces) }
        
        try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }

    func reject(proposal: Session.Proposal) async throws {
        try await Web3Wallet.instance.reject(proposalId: proposal.id, reason: .userRejected)
    }
}

extension SessionProposalInteractor {
    private func makeSessionNamespaces(namespaces: [String: ProposalNamespace], sessionNamespaces: inout [String: SessionNamespace]) {
        namespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            var accounts = Set<Account>()
            if let chains = proposalNamespace.chains {
                accounts = Set(
                    chains.compactMap {
                        Account($0.absoluteString + ":\(self.accounts[$0.namespace]!)")
                    }
                )
                let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
                sessionNamespaces[caip2Namespace] = sessionNamespace
            } else {
                if let network = $0.key.components(separatedBy: ":").first,
                   let chain = $0.key.components(separatedBy: ":").last
                {
                    accounts = Set([Account(network + ":\(chain)" + ":\(self.accounts[network]!)")!])
                    let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
                    sessionNamespaces[$0.key] = sessionNamespace
                }
            }
        }
    }
}
