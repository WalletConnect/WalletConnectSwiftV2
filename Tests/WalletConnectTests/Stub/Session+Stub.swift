@testable import WalletConnect

extension SessionSequence {
    
    static func stubPreSettled() -> SessionSequence {
        SessionSequence(
            topic: String.generateTopic()!,
            relay: RelayProtocolOptions.stub(),
            selfParticipant: Participant.stub(),
            expiryDate: Date.distantFuture,
            settledState: Settled(
                peer: Participant.stub(),
                permissions: SessionPermissions.stub(),
                state: SessionState(accounts: []),
                status: .preSettled
            )
        )
    }
    
    static func stubSettled() -> SessionSequence {
        SessionSequence(
            topic: String.generateTopic()!,
            relay: RelayProtocolOptions.stub(),
            selfParticipant: Participant.stub(),
            expiryDate: Date.distantFuture,
            settledState: Settled(
                peer: Participant.stub(),
                permissions: SessionPermissions.stub(),
                state: SessionState(accounts: []),
                status: .acknowledged
            )
        )
    }
}
