@testable import WalletConnect
import Foundation
import WalletConnectKMS

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
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000)) -> Pairing {
        Pairing(topic: String.generateTopic()!, peer: nil, expiryDate: expiryDate)
    }
}

extension Session.Permissions {
    static func stub(
        methods: Set<String> = ["getGenesisHash"],
        notifications: [String] = ["msg"]
    ) -> Session.Permissions {
        Session.Permissions(
            methods: methods,
            notifications: notifications
        )
    }
}

extension SessionPermissions {
    static func stub(
        jsonrpc: Set<String> = ["eth_sign"],
        notifications: [String] = ["a_type"],
        controllerKey: String = AgreementPrivateKey().publicKey.hexRepresentation
    ) -> SessionPermissions {
        return SessionPermissions(
            jsonrpc: JSONRPC(methods: jsonrpc),
            notifications: Notifications(types: notifications),
            controller: Controller(publicKey: controllerKey)
        )
    }
}

extension BlockchainProposed {
    static func stub(chains: Set<String> = ["eip155:1"]) -> BlockchainProposed {
        return BlockchainProposed(chains: chains)
    }
}

extension RelayProtocolOptions {
    static func stub() -> RelayProtocolOptions {
        RelayProtocolOptions(protocol: "", data: nil)
    }
}

extension Participant {
    static func stub(publicKey: String = AgreementPrivateKey().publicKey.hexRepresentation) -> Participant {
        Participant(publicKey: publicKey, metadata: AppMetadata.stub())
    }
}

extension WCRequestSubscriptionPayload {
    static func stubUpdate(topic: String, accounts: [String] = ["std:0:0"]) -> WCRequestSubscriptionPayload {
        let updateMethod = WCMethod.wcSessionUpdate(SessionType.UpdateParams(state: SessionState(accounts: accounts))).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateMethod)
    }
    
    static func stubUpgrade(topic: String, permissions: SessionPermissions = SessionPermissions(permissions: Session.Permissions.stub())) -> WCRequestSubscriptionPayload {
        let upgradeMethod = WCMethod.wcSessionUpgrade(SessionType.UpgradeParams(permissions: permissions)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: upgradeMethod)
    }
    
    static func stubExtend(topic: String, ttl: Int) -> WCRequestSubscriptionPayload {
        let extendMethod = WCMethod.wcSessionExtend(SessionType.ExtendParams(ttl: ttl)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: extendMethod)
    }
}
