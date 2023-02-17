import WalletConnectSign

extension ProposalNamespace {
    static func stubRequired() -> [String: ProposalNamespace] {
        return [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"])
        ]
    }
}

extension SessionNamespace {
    static func make(toRespond namespaces: [String: ProposalNamespace]) -> [String: SessionNamespace] {
        return namespaces.mapValues { proposalNamespace in
            SessionNamespace(
                accounts: Set(proposalNamespace.chains!.map { Account(blockchain: $0, address: "0x00")! }),
                methods: proposalNamespace.methods,
                events: proposalNamespace.events
            )
        }
    }
}
