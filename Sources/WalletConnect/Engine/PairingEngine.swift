import Foundation

final class PairingEngine: SequenceEngine {
    private let wcSubscriber: WCSubscribing
    private let relayer: Relaying
    private let crypto: Crypto
    let sequences: Sequences<Pairing>
    var onSessionProposal: ((SessionType.Proposal)->())?
    var onPairingSettled: ((PairingType.Settled)->())?
    
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
            case .pairingApprove(let approveParams):
                handlePairingApprove(approveParams)
            case .pairingReject(_):
                fatalError("Not Implemented")
            case .pairingUpdate(_):
                fatalError("Not Implemented")
            case .pairingUpgrade(_):
                fatalError("Not Implemented")
            case .pairingDelete(let deleteParams):
                handleSequenceDelete(deleteParams, topic: subscriptionPayload.topic)
            case .pairingPayload(let pairingPayload):
                self.handlePairingPayload(pairingPayload, for: subscriptionPayload.topic)
            default:
                fatalError("not expected method type")
            }
        }
    }
    
    private func handlePairingPayload(_ payload: PairingType.PayloadParams, for topic: String) {
        guard let _ = sequences.get(topic: topic) else {
            Logger.error("Pairing for the topic: \(topic) does not exist")
            return
        }
        guard payload.request.method == PairingType.PayloadMethods.sessionPropose else {
            Logger.error("Forbidden WCPairingPayload method")
            return
        }
        let sessionProposal = payload.request.params.params
        onSessionProposal?(sessionProposal)
    }
    
    private func handleSequenceDelete(_ deleteParams: PairingType.DeleteParams, topic: String) {
        Logger.debug("-------------------------------------")
        Logger.debug("Paired client removed pairing - reason: \(deleteParams.reason.message), code: \(deleteParams.reason.code)")
        Logger.debug("-------------------------------------")
        sequences.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
    }
    
    private func handlePairingApprove(_ approveParams: PairingType.ApproveParams) {
        Logger.debug("Responder Client approved pairing on topic: \(approveParams.topic)")
        guard let pairing = sequences.get(topic: approveParams.topic),
              case let .pending(sequencePending) = pairing.sequenceState,
              let pairingPending = sequencePending as? PairingType.Pending else {
          fatalError()
        }
        let selfPublicKey = Data(hex: pairingPending.`self`.publicKey)
        let privateKey = try! crypto.getPrivateKey(for: selfPublicKey)!
        let peerPublicKey = Data(hex: approveParams.responder.publicKey)
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(peerPublicKey: peerPublicKey, privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        let proposal = pairingPending.proposal
        let controllerKey = proposal.proposer.controller ? selfPublicKey.toHexString() : proposal.proposer.publicKey
        let controller = Controller(publicKey: controllerKey)
   
        let settledPairing = PairingType.Settled(
            topic: settledTopic,
            relay: approveParams.relay,
            sharedKey: agreementKeys.sharedSecret.toHexString(),
            self: PairingType.Participant(publicKey: selfPublicKey.toHexString()),
            peer: PairingType.Participant(publicKey: approveParams.responder.publicKey),
            permissions: PairingType.Permissions(
                jsonrpc: proposal.permissions.jsonrpc,
                controller: controller),
            expiry: approveParams.expiry,
            state: approveParams.state)
        
        sequences.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledPairing))
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
    }
    
}
