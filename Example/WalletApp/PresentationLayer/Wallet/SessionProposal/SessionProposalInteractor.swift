import Foundation

import Web3Wallet

final class SessionProposalInteractor {
    func approve(proposal: Session.Proposal) async throws {
        // Following properties are used to support all the required namespaces for the testing purposes
        let supportedMethods = Array(proposal.requiredNamespaces.map { $0.value.methods }.first ?? [])
        let supportedEvents = Array(proposal.requiredNamespaces.map { $0.value.events }.first ?? [])
        let supportedChains = Array((proposal.requiredNamespaces.map { $0.value.chains }.first ?? [] )!)
        let supportedAccounts = supportedChains.map { Account(blockchain: $0, address: ETHSigner.address)! }
        
        /* Use only supported values for production. I.e:
        let supportedMethods = ["eth_signTransaction", "personal_sign", "eth_signTypedData", "eth_sendTransaction", "eth_sign"]
        let supportedEvents = ["accountsChanged", "chainChanged"]
        let supportedChains = [Blockchain("eip155:1")!, Blockchain("eip155:5")!]
        let supportedAccounts = [Account(blockchain: Blockchain("eip155:5")!, address: ETHSigner.address)!]
        */
        do {
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: proposal,
                chains: supportedChains,
                methods: supportedMethods,
                events: supportedEvents,
                accounts: supportedAccounts
            )
            try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
        } catch {
            print(error)
        }
    }

    func reject(proposal: Session.Proposal) async throws {
        try await Web3Wallet.instance.reject(proposalId: proposal.id, reason: .userRejected)
    }
}
