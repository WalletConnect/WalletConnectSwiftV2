import Foundation

import Web3Wallet

final class SessionProposalInteractor {
    lazy var accounts = [
        "eip155": ETHSigner.address,
        "solana": SOLSigner.address
    ]

    var sessionNamespaces = [String: SessionNamespace]()
    
    func approve(proposal: Session.Proposal) async throws {
        makeSessionNamespaces(namespaces: proposal.requiredNamespaces)
        proposal.optionalNamespaces.flatMap { makeSessionNamespaces(namespaces: $0) }
        
        try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }

    func reject(proposal: Session.Proposal) async throws {
        try await Web3Wallet.instance.reject(proposalId: proposal.id, reason: .userRejected)
    }
}

extension SessionProposalInteractor {
    private func makeSessionNamespaces(namespaces: [String: ProposalNamespace]) {
        namespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            var accounts = Set<Account>()
            if let chains = proposalNamespace.chains {
                accounts = Set(
                    chains.compactMap {
                        Account($0.absoluteString + ":\(self.accounts[$0.namespace] ?? "\($0.namespace)")")
                    }
                )
                let sessionNamespace = SessionNamespace(chains: chains, accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
                if sessionNamespaces[caip2Namespace] == nil {
                    sessionNamespaces[caip2Namespace] = sessionNamespace
                } else {
                    let unionChains = sessionNamespaces[caip2Namespace]?.chains!.union(sessionNamespace.chains ?? [])
                    sessionNamespaces[caip2Namespace]?.chains = unionChains
                    let unionAccounts = sessionNamespaces[caip2Namespace]?.accounts.union(sessionNamespace.accounts)
                    sessionNamespaces[caip2Namespace]?.accounts = unionAccounts ?? []
                    let unionMethods = sessionNamespaces[caip2Namespace]?.methods.union(sessionNamespace.methods)
                    sessionNamespaces[caip2Namespace]?.methods = unionMethods ?? []
                    let unionEvents = sessionNamespaces[caip2Namespace]?.events.union(sessionNamespace.events)
                    sessionNamespaces[caip2Namespace]?.events = unionEvents ?? []
                }
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
