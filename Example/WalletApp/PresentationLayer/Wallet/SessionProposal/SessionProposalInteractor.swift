import Foundation

import Web3Wallet
import WalletConnectRouter

final class SessionProposalInteractor {
    func approve(proposal: Session.Proposal, account: Account) async throws -> Bool {
        // Following properties are used to support all the required and optional namespaces for the testing purposes
        let supportedMethods = Set(proposal.requiredNamespaces.flatMap { $0.value.methods } + (proposal.optionalNamespaces?.flatMap { $0.value.methods } ?? []))
        let supportedEvents = Set(proposal.requiredNamespaces.flatMap { $0.value.events } + (proposal.optionalNamespaces?.flatMap { $0.value.events } ?? []))
        
        let supportedRequiredChains = proposal.requiredNamespaces["eip155"]?.chains ?? []
        let supportedOptionalChains = proposal.optionalNamespaces?["eip155"]?.chains ?? []
        var supportedChains = supportedRequiredChains + supportedOptionalChains 

        let supportedAccounts = Array(supportedChains).map { Account(blockchain: $0, address: account.address)! }

        /* Use only supported values for production. I.e:
        let supportedMethods = ["eth_signTransaction", "personal_sign", "eth_signTypedData", "eth_sendTransaction", "eth_sign"]
        let supportedEvents = ["accountsChanged", "chainChanged"]
        let supportedChains = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let supportedAccounts = [Account(blockchain: Blockchain("eip155:1")!, address: ETHSigner.address)!, Account(blockchain: Blockchain("eip155:137")!, address: ETHSigner.address)!]
        */
        var sessionNamespaces: [String: SessionNamespace]!

        do {
            sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: proposal,
                chains: Array(supportedChains),
                methods: Array(supportedMethods),
                events: Array(supportedEvents),
                accounts: supportedAccounts
            )
        } catch let error as AutoNamespacesError {
            try await reject(proposal: proposal, reason: RejectionReason(from: error))
            AlertPresenter.present(message: error.localizedDescription, type: .error)
            return false
        } catch {
            try await reject(proposal: proposal, reason: .userRejected)
            AlertPresenter.present(message: error.localizedDescription, type: .error)
            return false
        }
        _ = try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces, sessionProperties: proposal.sessionProperties)
        if let uri = proposal.proposer.redirect?.native {
            WalletConnectRouter.goBack(uri: uri)
            return false
        } else {
            return true
        }
    }

    func reject(proposal: Session.Proposal, reason: RejectionReason = .userRejected) async throws {
        try await Web3Wallet.instance.rejectSession(proposalId: proposal.id, reason: .userRejected)
        /* Redirect */
        if let uri = proposal.proposer.redirect?.native {
            WalletConnectRouter.goBack(uri: uri)
        }
    }
}
