import Foundation
import WalletConnectKMS
@testable import WalletConnect

//extension PairingSequence {
//    static func stubSettled(isSelfController: Bool) -> PairingSequence {
//        let peerKey = AgreementPrivateKey().publicKey.hexRepresentation
//        let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
//        let permissions = isSelfController ? SessionPermissions.stub(controllerKey: selfKey) : SessionPermissions.stub(controllerKey: peerKey)
//        
//        return PairingSequence(
//            topic: String.generateTopic()!,
//            relay: RelayProtocolOptions.stub(),
//            selfParticipant: Participant.stub(publicKey: selfKey),
//            expiryDate: Date.distantFuture,
//            settledState: Settled(
//                peer: Participant.stub(publicKey: peerKey),
//                permissions: permissions,
//                state: PairingState(metadata: nil),
//                status: .acknowledged))
//    }
//}
