import Foundation

import Web3Wallet

final class SessionProposalInteractor {
    func approve(proposal: Session.Proposal) async throws {
        do {
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: proposal,
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:5")!],
                methods: ["eth_signTransaction", "personal_sign", "eth_signTypedData", "eth_sendTransaction", "eth_sign"],
                events: ["accountsChanged", "chainChanged"],
                accounts: [
                    Account(blockchain: Blockchain("eip155:5")!, address: ETHSigner.address)!,
                    Account(blockchain: Blockchain("eip155:1")!, address: ETHSigner.address)!,
                    Account(blockchain: Blockchain("eip155:137")!, address: ETHSigner.address)!
                ]
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
