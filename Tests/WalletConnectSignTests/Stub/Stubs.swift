@testable import WalletConnectSign
import Foundation
import WalletConnectKMS
import WalletConnectUtils
import TestingUtils
import WalletConnectPairing

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
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), topic: String = String.generateTopic()) -> Pairing {
        Pairing(topic: topic, peer: nil, expiryDate: expiryDate)
    }
}

extension WCPairing {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), isActive: Bool = true, topic: String = String.generateTopic()) -> WCPairing {
        WCPairing(topic: topic, relay: RelayProtocolOptions.stub(), peerMetadata: AppMetadata.stub(), isActive: isActive, expiryDate: expiryDate)
    }
}

extension ProposalNamespace {
    static func stubDictionary() -> [String: ProposalNamespace] {
        return [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
    }
}

extension SessionNamespace {
    static func stubDictionary() -> [String: SessionNamespace] {
        return [
            "eip155": SessionNamespace(
                accounts: [Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
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

    static func stubUpdateNamespaces(topic: String, namespaces: [String: SessionNamespace] = SessionNamespace.stubDictionary()) -> WCRequestSubscriptionPayload {
        let updateMethod = WCMethod.wcSessionUpdate(SessionType.UpdateParams(namespaces: namespaces)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateMethod)
    }

    static func stubUpdateExpiry(topic: String, expiry: Int64) -> WCRequestSubscriptionPayload {
        let updateExpiryMethod = WCMethod.wcSessionExtend(SessionType.UpdateExpiryParams(expiry: expiry)).asRequest()
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: updateExpiryMethod)
    }

    static func stubSettle(topic: String) -> WCRequestSubscriptionPayload {
        let method = WCMethod.wcSessionSettle(SessionType.SettleParams.stub())
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: method.asRequest())
    }

    static func stubRequest(topic: String, method: String, chainId: Blockchain) -> WCRequestSubscriptionPayload {
        let params = SessionType.RequestParams(
            request: SessionType.RequestParams.Request(method: method, params: AnyCodable(EmptyCodable())),
            chainId: chainId)
        let request = WCRequest(method: .sessionRequest, params: .sessionRequest(params))
        return WCRequestSubscriptionPayload(topic: topic, wcRequest: request)
    }
}

extension SessionProposal {
    static func stub(proposerPubKey: String = "") -> SessionProposal {
        let relayOptions = RelayProtocolOptions(protocol: "irn", data: nil)
        return SessionType.ProposeParams(
            relays: [relayOptions],
            proposer: Participant(publicKey: proposerPubKey, metadata: AppMetadata.stub()),
            requiredNamespaces: ProposalNamespace.stubDictionary())
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
