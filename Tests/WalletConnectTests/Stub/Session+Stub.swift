import Foundation
import WalletConnectKMS
@testable import WalletConnect

extension SessionSequence {
    static func stub(
        isSelfController: Bool = false,
        expiryDate: Date = Date.distantFuture,
        selfPrivateKey: AgreementPrivateKey = AgreementPrivateKey(),
        acknowledged: Bool = true) -> SessionSequence {
            let peerKey = selfPrivateKey.publicKey.hexRepresentation
            let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
            let permissions = SessionPermissions.stub()
            let controllerKey = isSelfController ? selfKey : peerKey
            return SessionSequence(
                topic: String.generateTopic(),
                relay: RelayProtocolOptions.stub(),
                controller: AgreementPeer(publicKey: controllerKey),
                participants: Participants(self: Participant.stub(publicKey: selfKey), peer: Participant.stub(publicKey: peerKey)),
                blockchain: SessionType.Blockchain.stub(),
                permissions: permissions,
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
        return SessionType.SettleParams(relay: RelayProtocolOptions.stub(), blockchain: SessionType.Blockchain.stub(), permissions: SessionPermissions.stub(), controller: Participant.stub(), expiry: Int64(Date.distantFuture.timeIntervalSince1970))
    }
}
