import Foundation
import WalletConnectKMS
@testable import WalletConnect

extension SessionSequence {
    static func stubUnacknowledged(
        isSelfController: Bool = false,
        expiryDate: Date = Date.distantFuture) -> SessionSequence {
            let peerKey = AgreementPrivateKey().publicKey.hexRepresentation
            let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
            let permissions = SessionPermissions.stub()
            let controllerKey = isSelfController ? selfKey : peerKey
            
            return SessionSequence(
                topic: String.generateTopic(),
                relay: RelayProtocolOptions.stub(),
                controller: AgreementPeer(publicKey: controllerKey),
                participants: Participants(self: Participant.stub(publicKey: selfKey), peer: Participant.stub(publicKey: peerKey)),
                blockchain: Blockchain.stub(),
                permissions: permissions,
                acknowledged: false)
        }
    
    static func stubAcknowledged(
        isSelfController: Bool,
        expiryDate: Date = Date.distantFuture) -> SessionSequence {
            let peerKey = AgreementPrivateKey().publicKey.hexRepresentation
            let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
            let permissions = SessionPermissions.stub()
            let controllerKey = isSelfController ? selfKey : peerKey

            return SessionSequence(
                topic: String.generateTopic(),
                relay: RelayProtocolOptions.stub(),
                controller: AgreementPeer(publicKey: controllerKey),
                participants: Participants(self: Participant.stub(publicKey: selfKey), peer: Participant.stub(publicKey: peerKey)),
                blockchain: Blockchain.stub(),
                permissions: permissions,
                acknowledged: true)
        }
}

extension Account {
    static func stubSet() -> Set<Account> {
        return Set(["chainstd:0:0", "chainstd:1:1", "chainstd:2:2"].map { Account($0)! })
    }
}

