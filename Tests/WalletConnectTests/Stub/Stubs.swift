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
    static func stubUpdateAccounts(topic: String, accounts: Set<String> = ["std:0:0"]) -> WCRequestSubscriptionPayload {
        let updateMethod = WCMethod.wcSessionUpdateAccounts(SessionType.UpdateAccountsParams(accounts: accounts)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateMethod)
    }
    
    static func stubUpdateMethods(topic: String, methods: Set<String> = ["method"]) -> WCRequestSubscriptionPayload {
        let updateMethod = WCMethod.wcSessionUpdateMethods(SessionType.UpdateMethodsParams(methods: methods)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateMethod)
    }
    
    static func stubUpdateEvents(topic: String, events: Set<String> = ["event"]) -> WCRequestSubscriptionPayload {
        let updateEvent = WCMethod.wcSessionUpdateEvents(SessionType.UpdateEventsParams(events: events)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateEvent)
    }
    
    static func stubUpdateExpiry(topic: String, expiry: Int64) -> WCRequestSubscriptionPayload {
        let updateExpiryMethod = WCMethod.wcSessionUpdateExpiry(SessionType.UpdateExpiryParams(expiry: expiry)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateExpiryMethod)
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
            methods: [],
            events: [],
            chains: [])
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
