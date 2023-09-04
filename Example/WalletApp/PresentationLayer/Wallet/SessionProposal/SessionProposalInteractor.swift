import Foundation

import Web3Wallet

final class SessionProposalInteractor {
    func approve(proposal: Session.Proposal, account: Account) async throws {
        // Following properties are used to support all the required and optional namespaces for the testing purposes
        let supportedMethods = Set(proposal.requiredNamespaces.flatMap { $0.value.methods } + (proposal.optionalNamespaces?.flatMap { $0.value.methods } ?? []))
        let supportedEvents = Set(proposal.requiredNamespaces.flatMap { $0.value.events } + (proposal.optionalNamespaces?.flatMap { $0.value.events } ?? []))
        
        let supportedRequiredChains = proposal.requiredNamespaces["eip155"]?.chains
        let supportedOptionalChains = proposal.optionalNamespaces?["eip155"]?.chains ?? []
        let supportedChains = supportedRequiredChains?.union(supportedOptionalChains) ?? []
        
        let supportedAccounts = Array(supportedChains).map { Account(blockchain: $0, address: account.address)! }
        
        /* Use only supported values for production. I.e:
        let supportedMethods = ["eth_signTransaction", "personal_sign", "eth_signTypedData", "eth_sendTransaction", "eth_sign"]
        let supportedEvents = ["accountsChanged", "chainChanged"]
        let supportedChains = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let supportedAccounts = [Account(blockchain: Blockchain("eip155:1")!, address: ETHSigner.address)!, Account(blockchain: Blockchain("eip155:137")!, address: ETHSigner.address)!]
        */
        let sessionNamespaces = try AutoNamespaces.build(
            sessionProposal: proposal,
            chains: Array(supportedChains),
            methods: Array(supportedMethods),
            events: Array(supportedEvents),
            accounts: supportedAccounts
        )
        try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces, sessionProperties: proposal.sessionProperties)
    }

    func reject(proposal: Session.Proposal) async throws {
        try await Web3Wallet.instance.reject(proposalId: proposal.id, reason: .userRejected)
    }
}
