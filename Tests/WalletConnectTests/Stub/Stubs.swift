@testable import WalletConnect

extension AppMetadata {
    static func stub() -> AppMetadata {
        AppMetadata(
            name: "Wallet Connect",
            description: "A protocol to connect blockchain wallets to dapps.",
            url: "https://walletconnect.com/",
            icons: []
        )
    }
}

extension Pairing {
    static func stub() -> Pairing {
        Pairing(topic: String.generateTopic()!, peer: nil)
    }
}

extension SessionPermissions {
    static func stub() -> SessionPermissions {
        SessionPermissions(
            blockchain: Blockchain(chains: []),
            jsonrpc: JSONRPC(methods: []),
            notifications: Notifications(types: [])
        )
    }
}

extension RelayProtocolOptions {
    static func stub() -> RelayProtocolOptions {
        RelayProtocolOptions(protocol: "", params: nil)
    }
}

extension Participant {
    static func stub() -> Participant {
        Participant(publicKey: AgreementPrivateKey().publicKey.hexRepresentation, metadata: AppMetadata.stub())
    }
}
