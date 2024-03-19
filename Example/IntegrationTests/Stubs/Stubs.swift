import WalletConnectSign

extension ProposalNamespace {
    static func stubRequired(chains: [Blockchain] = [Blockchain("eip155:1")!]) -> [String: ProposalNamespace] {
        return [
            "eip155": ProposalNamespace(
                chains: chains,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"])
        ]
    }
}

extension SessionNamespace {
    static func make(toRespond namespaces: [String: ProposalNamespace]) -> [String: SessionNamespace] {
        return namespaces.mapValues { proposalNamespace in
            SessionNamespace(
                accounts: proposalNamespace.chains!.map { Account(blockchain: $0, address: "0x00")! },
                methods: proposalNamespace.methods,
                events: proposalNamespace.events
            )
        }
    }
}

extension AppMetadata {
    static func stub() -> AppMetadata {
        return AppMetadata(
            name: "WalletConnectSwift",
            description: "WalletConnectSwift",
            url: "https://walletconnect.com",
            icons: [],
            redirect: AppMetadata.Redirect(native: "wcdapp://", universal: nil)
        )
    }
}
