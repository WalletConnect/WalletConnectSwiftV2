import Foundation

import Web3Wallet

final class SessionRequestInteractor {
    private let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
    private let account = Account("eip155:1:0xe5EeF1368781911d265fDB6946613dA61915a501")!

    func approve(proposal: Session.Proposal) async throws {
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(account.namespace)") })

            let extensions: [SessionNamespace.Extension]? = proposalNamespace.extensions?.map { element in
                let accounts = Set(element.chains.compactMap { Account($0.absoluteString + ":\(account.namespace)") })
                return SessionNamespace.Extension(accounts: accounts, methods: element.methods, events: element.events)
            }
            let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events, extensions: extensions)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        
        try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }

    func reject(proposal: Session.Proposal) async throws {
        try await Web3Wallet.instance.reject(proposalId: proposal.id, reason: .userRejected)
    }

    func formatted(request: AuthRequest) -> String {
        return try! Web3Wallet.instance.formatMessage(
            payload: request.payload,
            address: account.address
        )
    }
}
