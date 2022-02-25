import Foundation
import WalletConnectKMS
@testable import WalletConnect

extension SessionSequence {
    
    static func stubPreSettled(
        isSelfController: Bool = false,
        expiryDate: Date = Date.distantFuture) -> SessionSequence {
            let peerKey = AgreementPrivateKey().publicKey.hexRepresentation
            let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
            let permissions = isSelfController ? SessionPermissions.stub(controllerKey: selfKey) : SessionPermissions.stub(controllerKey: peerKey)
        return SessionSequence(
            topic: String.generateTopic(),
            relay: RelayProtocolOptions.stub(),
            selfParticipant: Participant.stub(publicKey: selfKey),
            expiryDate: expiryDate,
            settledState: Settled(
                peer: Participant.stub(publicKey: peerKey),
                permissions: permissions,
                accounts: Account.stubSet(),
                status: .preSettled
            )
        )
    }
    
    static func stubSettled(
        isSelfController: Bool,
        expiryDate: Date = Date.distantFuture) -> SessionSequence {
        let peerKey = AgreementPrivateKey().publicKey.hexRepresentation
        let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
        let permissions = isSelfController ? SessionPermissions.stub(controllerKey: selfKey) : SessionPermissions.stub(controllerKey: peerKey)
        return SessionSequence(
            topic: String.generateTopic(),
            relay: RelayProtocolOptions.stub(),
            selfParticipant: Participant.stub(publicKey: selfKey),
            expiryDate: expiryDate,
            settledState: Settled(
                peer: Participant.stub(publicKey: peerKey),
                permissions: permissions,
                accounts: Account.stubSet(),
                status: .acknowledged
            )
        )
    }
}

extension Account {
    static func stubSet() -> Set<Account> {
        return Set(["chainstd:0:0", "chainstd:1:1", "chainstd:2:2"].map { Account($0)! })
    }
}
