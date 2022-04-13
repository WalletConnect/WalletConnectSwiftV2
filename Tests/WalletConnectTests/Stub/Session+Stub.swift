import Foundation
import WalletConnectKMS
@testable import WalletConnect

extension WCSession {
    static func stub(
        isSelfController: Bool = false,
        expiryDate: Date = Date.distantFuture,
        selfPrivateKey: AgreementPrivateKey = AgreementPrivateKey(),
        acknowledged: Bool = true) -> WCSession {
            let peerKey = selfPrivateKey.publicKey.hexRepresentation
            let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
            let controllerKey = isSelfController ? selfKey : peerKey
            return WCSession(
                topic: String.generateTopic(),
                relay: RelayProtocolOptions.stub(),
                controller: AgreementPeer(publicKey: controllerKey),
                participants: Participants(self: Participant.stub(publicKey: selfKey), peer: Participant.stub(publicKey: peerKey)),
                methods: [],
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
            controller: Participant.stub(), accounts: Account.stubSet(),
            methods: [],
            events: [],
            expiry: Int64(Date.distantFuture.timeIntervalSince1970))
    }
}
