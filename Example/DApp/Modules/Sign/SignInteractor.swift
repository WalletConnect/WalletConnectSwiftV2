import Foundation

import WalletConnectSign

enum Proposal {
    static let requiredNamespaces: [String: ProposalNamespace] = [
        "eip155": ProposalNamespace(
            chains: [
                Blockchain("eip155:1")!,
                Blockchain("eip155:137")!
            ],
            methods: [
                "eth_sendTransaction",
                "personal_sign",
                "eth_signTypedData"
            ], events: []
        )
    ]
    
    static let optionalNamespaces: [String: ProposalNamespace] = [
        "solana": ProposalNamespace(
            chains: [
                Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!
            ],
            methods: [
                "solana_signMessage",
                "solana_signTransaction"
            ], events: []
        )
    ]
}

struct Chain {
    let name: String
    let id: String
}

final class SignInteractor {}
