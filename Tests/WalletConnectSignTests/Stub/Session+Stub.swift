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
                requiredNamespaces: requiredNamespaces,
                events: [],
                accounts: Account.stubSet(),
                acknowledged: acknowledged,
                expiry: Int64(expiryDate.timeIntervalSince1970))
        }
}

extension Account {
    static func stubSet() -> Set<Account> {
        return Set(["chainstd:0:0", "chainstd:1:1", "chainstd:2:2"].map { Account($0)! })
    }
}

extension SessionType.SettleParams {
    static func stub() -> SessionType.SettleParams {
        return SessionType.SettleParams(
            relay: RelayProtocolOptions.stub(),
            controller: Participant.stub(),
            namespaces: SessionNamespace.stubDictionary(),
            expiry: Int64(Date.distantFuture.timeIntervalSince1970))
    }
}
