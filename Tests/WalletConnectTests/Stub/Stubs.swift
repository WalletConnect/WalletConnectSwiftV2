@testable import WalletConnect
import Foundation
import WalletConnectKMS
import WalletConnectUtils

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
        Pairing(topic: String.generateTopic(), peer: nil, expiryDate: expiryDate)
    }
}

extension PairingSequence {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), isActive: Bool = true) -> PairingSequence {
        PairingSequence(topic: String.generateTopic(), relay: RelayProtocolOptions.stub(), participants: Participants(self: nil, peer: nil), isActive: isActive, expiryDate: expiryDate)
    }
}

extension Session.Permissions {
    static func stub(
        methods: Set<String> = ["getGenesisHash"],
        notifications: Set<String> = ["msg"]
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
        notifications: Set<String> = ["a_type"]
    ) -> SessionPermissions {
        return SessionPermissions(
            jsonrpc: JSONRPC(methods: jsonrpc),
            notifications: Notifications(types: notifications)
        )
    }
}

extension Blockchain {
    static func stub(chains: Set<String> = ["eip155:1"]) -> Blockchain {
        return Blockchain(chains: chains, accounts: [])
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

extension AgreementPeer {
    static func stub(publicKey: String = AgreementPrivateKey().publicKey.hexRepresentation) -> AgreementPeer {
        AgreementPeer(publicKey: publicKey)
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
    
    static func stubExtend(topic: String, expiry: Int64) -> WCRequestSubscriptionPayload {
        let extendMethod = WCMethod.wcSessionExtend(SessionType.ExtendParams(expiry: expiry)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: extendMethod)
    }
    
    static func stubSettle(topic: String) -> WCRequestSubscriptionPayload {
        let method = WCMethod.wcSessionSettle(SessionType.SettleParams.stub())
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: method.asRequest())
    }
}

extension SessionProposal {
    static func stub(proposerPubKey: String) -> SessionProposal {
        let relayOptions = RelayProtocolOptions(protocol: "waku", data: nil)
        return SessionType.ProposeParams(
            relays: [relayOptions],
            proposer: Participant(publicKey: proposerPubKey, metadata: AppMetadata.stub()),
            permissions: SessionPermissions.stub(),
            blockchain: SessionProposal.ProposedBlockchain(chains: []))
    }
}

extension WCResponse {
    static func stubError(forRequest request: WCRequest, topic: String) -> WCResponse {
        let errorResponse = JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
        return WCResponse(
            topic: topic,
            chainId: nil,
            requestMethod: request.method,
            requestParams: request.params,
            result: .error(errorResponse)
        )
    }
}
