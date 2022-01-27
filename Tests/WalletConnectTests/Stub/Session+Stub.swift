import Foundation
@testable import WalletConnect

extension SessionSequence {
    
    static func stubPreSettled(isPeerController: Bool = false) -> SessionSequence {
        let peerKey = AgreementPrivateKey().publicKey.hexRepresentation
        let permissions = isPeerController ? SessionPermissions.stub(controllerKey: peerKey) : SessionPermissions.stub()
        return SessionSequence(
            topic: String.generateTopic()!,
            relay: RelayProtocolOptions.stub(),
            selfParticipant: Participant.stub(),
            expiryDate: Date.distantFuture,
            settledState: Settled(
                peer: Participant.stub(publicKey: peerKey),
                permissions: permissions,
                state: SessionState(accounts: ["chainstd:1:1"]),
                status: .preSettled
            )
        )
    }
    
    static func stubSettled(isPeerController: Bool = false) -> SessionSequence {
        let peerKey = AgreementPrivateKey().publicKey.hexRepresentation
        let permissions = isPeerController ? SessionPermissions.stub(controllerKey: peerKey) : SessionPermissions.stub()
        return SessionSequence(
            topic: String.generateTopic()!,
            relay: RelayProtocolOptions.stub(),
            selfParticipant: Participant.stub(),
            expiryDate: Date.distantFuture,
            settledState: Settled(
                peer: Participant.stub(publicKey: peerKey),
                permissions: permissions,
                state: SessionState(accounts: ["chainstd:1:1"]),
                status: .acknowledged
            )
        )
    }
}
