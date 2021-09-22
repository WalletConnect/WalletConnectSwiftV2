import Foundation

final class PairingEngine: SequenceEngine {
    private let wcSubscriber: WCSubscribing
    private let relayer: Relaying
    private let crypto: Crypto
    let sequences: Sequences<Pairing>
    var onSessionProposal: ((SessionType.Proposal, Pairing)->())?
    
    init(relay: Relaying,
         crypto: Crypto,
         subscriber: WCSubscribing,
         sequences: Sequences<Pairing> = Sequences<Pairing>()) {
        self.relayer = relay
        self.crypto = crypto
        self.wcSubscriber = subscriber
        self.sequences = sequences
        setUpWCRequestHandling()
    }
    
    func respond(to proposal: PairingType.Proposal, completion: @escaping (Result<String, Error>) -> Void) {
        let privateKey = Crypto.X25519.generatePrivateKey()
        let selfPublicKey = privateKey.publicKey.toHexString()
        
        let pendingPairing = PairingType.Pending(
            status: .responded,
            topic: proposal.topic,
            relay: proposal.relay,
            self: PairingType.Participant(publicKey: selfPublicKey),
            proposal: proposal)
        
        wcSubscriber.setSubscription(topic: proposal.topic)
        sequences.create(topic: proposal.topic, sequenceState: .pending(pendingPairing))
        // settle on topic B
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(
            peerPublicKey: Data(hex: proposal.proposer.publicKey),
            privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : selfPublicKey
        let settledPairing = PairingType.Settled(
            topic: settledTopic,
            relay: proposal.relay,
            sharedKey: agreementKeys.sharedSecret.toHexString(),
            self: PairingType.Participant(publicKey: selfPublicKey),
            peer: PairingType.Participant(publicKey: proposal.proposer.publicKey),
            permissions: PairingType.Permissions(
                jsonrpc: proposal.permissions.jsonrpc,
                controller: Controller(publicKey: controllerKey)),
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil) // FIXME: State
        
                
        wcSubscriber.setSubscription(topic: settledTopic)
        sequences.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledPairing))
        
        crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        crypto.set(privateKey: privateKey)
        
        // publish approve on topic A
        let approveParams = PairingType.ApproveParams(
            topic: proposal.topic,
            relay: proposal.relay,
            responder: PairingType.Participant(publicKey: selfPublicKey),
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil) // FIXME: State
        let approvalPayload = ClientSynchJSONRPC(method: .pairingApprove, params: .pairingApprove(approveParams))
        
        _ = try? relayer.publish(topic: proposal.topic, payload: approvalPayload) { [weak self] result in
            switch result {
            case .success:
                self?.wcSubscriber.removeSubscription(topic: proposal.topic)
                print("Success on wc_pairingApprove")
                completion(.success(proposal.topic))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func setUpWCRequestHandling() {
        wcSubscriber.onSubscription = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.clientSynchJsonRpc.params {
            case .pairingApprove(_):
                fatalError("Not Implemented")
            case .pairingReject(_):
                fatalError("Not Implemented")
            case .pairingUpdate(_):
                fatalError("Not Implemented")
            case .pairingUpgrade(_):
                fatalError("Not Implemented")
            case .pairingDelete(let deleteParams):
                manageSequenceDelete(deleteParams, topic: subscriptionPayload.topic)
            case .pairingPayload(let pairingPayload):
                self.managePairingPayload(pairingPayload, for: subscriptionPayload.topic)
            default:
                fatalError("not expected method type")
            }
        }
    }
    
    private func managePairingPayload(_ payload: PairingType.PayloadParams, for topic: String) {
        guard let pairing = sequences.get(topic: topic) else {
            Logger.error("Pairing for the topic: \(topic) does not exist")
            return
        }
        guard payload.request.method == PairingType.PayloadMethods.sessionPropose else {
            Logger.error("Forbidden WCPairingPayload method")
            return
        }
        let sessionProposal = payload.request.params.params
        onSessionProposal?(sessionProposal, pairing)
    }
    
    private func manageSequenceDelete(_ deleteParams: PairingType.DeleteParams, topic: String) {
        Logger.debug("-------------------------------------")
        Logger.debug("Paired client removed pairing - reason: \(deleteParams.reason.message), code: \(deleteParams.reason.code)")
        Logger.debug("-------------------------------------")
        sequences.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
    }
}
