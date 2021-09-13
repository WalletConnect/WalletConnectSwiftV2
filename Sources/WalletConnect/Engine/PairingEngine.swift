import Foundation

final class PairingEngine: SequenceEngine {
    
    var pendingPairings: SequenceSubscribing!
    var settledPairings: SequenceSubscribing!
    
//    let history
    
    var relayer: Relaying!
    var crypto: Crypto!
    
    init() {
        
    }
    
    func respond(to proposal: PairingType.Proposal, completion: @escaping (Result<String, Error>) -> Void) {
        
        let privateKey = Crypto.X25519.generatePrivateKey()
        let publicKey = privateKey.publicKey.toHexString()
        
        let pendingPairing = PairingType.Pending(
            status: .responded,
            topic: proposal.topic,
            relay: proposal.relay,
            self: PairingType.Participant(publicKey: publicKey),
            proposal: proposal)
        
        pendingPairings.set(topic: proposal.topic, sequenceData: .pending(pendingPairing))
        
        // settle on topic B
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(
            peerPublicKey: Data(hex: proposal.proposer.publicKey),
            privateKey: privateKey)
        let topicB = agreementKeys.sharedSecret.sha256().toHexString()
        
        let settledPairing = PairingType.Settled(
            topic: topicB,
            relay: proposal.relay,
            sharedKey: agreementKeys.sharedSecret.toHexString(),
            self: PairingType.Participant(publicKey: publicKey),
            peer: PairingType.Participant(publicKey: proposal.proposer.publicKey),
            permissions: PairingType.Permissions(jsonrpc: proposal.permissions, controller: proposal.proposer.controller),
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil)
        settledPairings.set(topic: topicB, sequenceData: .settled(settledPairing))
        
        // publish approve on topic A
        let approveParams = PairingType.ApproveParams(
            topic: proposal.topic,
            relay: proposal.relay,
            responder: PairingType.Participant(publicKey: publicKey),
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil)
        let approvalPayload = ClientSynchJSONRPC(method: .pairingApprove, params: .pairingApprove(approveParams))
        
        _ = try? relayer.publish(topic: proposal.topic, payload: approvalPayload) { [weak self] result in
            switch result {
            case .success:
                self?.pendingPairings.remove(topic: proposal.topic)
                completion(.success(proposal.topic))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
