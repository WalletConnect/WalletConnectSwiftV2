import Foundation
import WalletConnectKMS
@testable import WalletConnectSign

extension WCSession {
    static func stub(
        topic: String = .generateTopic(),
        isSelfController: Bool = false,
        expiryDate: Date = Date.distantFuture,
        selfPrivateKey: AgreementPrivateKey = AgreementPrivateKey(),
        namespaces: [String: SessionNamespace] = [:],
        sessionProperties: [String: String] = [:],
        requiredNamespaces: [String: ProposalNamespace] = [:],
        acknowledged: Bool = true,
        timestamp: Date = Date()
    ) -> WCSession {
            let peerKey = selfPrivateKey.publicKey.hexRepresentation
            let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
            let controllerKey = isSelfController ? selfKey : peerKey
            return WCSession(
                topic: topic,
                pairingTopic: "",
                timestamp: timestamp,
                relay: RelayProtocolOptions.stub(),
                controller: AgreementPeer(publicKey: controllerKey),
                selfParticipant: Participant.stub(publicKey: selfKey),
                peerParticipant: Participant.stub(publicKey: peerKey),
                namespaces: namespaces,
                sessionProperties: sessionProperties,
                requiredNamespaces: requiredNamespaces,
                events: [],
                accounts: Account.stubSet(),
                acknowledged: acknowledged,
                expiryTimestamp: Int64(expiryDate.timeIntervalSince1970),
                transportType: .relay,
                verifyContext: VerifyContext(origin: nil, validation: .unknown))
        }
}

extension Account {
    static func stubSet() -> Set<Account> {
        return Set(["chainstd:0:0", "chainstd:1:1", "chainstd:2:2"].map { Account($0)! })
    }
}

extension Account {
    static func stub() -> Account {
        return Account("eip155:1:0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")!
    }
}

extension SessionType.SettleParams {
    static func stub() -> SessionType.SettleParams {
        return SessionType.SettleParams(
            relay: RelayProtocolOptions.stub(),
            controller: Participant.stub(),
            namespaces: SessionNamespace.stubDictionary(),
            sessionProperties: nil,
            expiry: Int64(Date.distantFuture.timeIntervalSince1970))
    }
}
