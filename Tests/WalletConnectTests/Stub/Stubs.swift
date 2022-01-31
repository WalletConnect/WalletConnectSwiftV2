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
    static func stub(controllerKey: String = AgreementPrivateKey().publicKey.hexRepresentation) -> SessionPermissions {
        SessionPermissions(
            blockchain: Blockchain(chains: []),
            jsonrpc: JSONRPC(methods: []),
            notifications: Notifications(types: []),
            controller: Controller(publicKey: controllerKey)
        )
    }
}

extension RelayProtocolOptions {
    static func stub() -> RelayProtocolOptions {
        RelayProtocolOptions(protocol: "", params: nil)
    }
}

extension Participant {
    static func stub(publicKey: String = AgreementPrivateKey().publicKey.hexRepresentation) -> Participant {
        Participant(publicKey: publicKey, metadata: AppMetadata.stub())
    }
}

extension WCRequestSubscriptionPayload {
    static func stubUpdate(topic: String, accounts: Set<String> = ["std:0:0"]) -> WCRequestSubscriptionPayload {
        let updateMethod = WCMethod.wcSessionUpdate(SessionType.UpdateParams(accounts: accounts)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateMethod)
    }
}
