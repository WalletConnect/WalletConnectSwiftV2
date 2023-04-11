import Foundation

import Web3Wallet

final class SessionProposalInteractor {
    func approve(proposal: Session.Proposal) async throws {
        let requiredMethods = proposal.requiredNamespaces.map { $0.value.methods }
        let requiredEvents = proposal.requiredNamespaces.map { $0.value.events }
        let requiredChains = proposal.requiredNamespaces.map { $0.value.chains }
        do {
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: proposal,
                chains: Array(requiredChains.first!!),
                methods: Array(requiredMethods.first!),
                events: Array(requiredEvents.first!),
                accounts: Set([
                    Account(blockchain: Blockchain("eip155:5")!, address: ETHSigner.address)!,
                    Account(blockchain: Blockchain("eip155:1")!, address: ETHSigner.address)!,
                    Account(blockchain: Blockchain("eip155:137")!, address: ETHSigner.address)!
                ])
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
