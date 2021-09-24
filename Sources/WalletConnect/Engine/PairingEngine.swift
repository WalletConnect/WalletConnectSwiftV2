import Foundation

final class PairingEngine: SequenceEngine {
    private let wcSubscriber: WCSubscribing
    private let relayer: Relaying
    private let crypto: Crypto
    private var isController: Bool
    let sequences: Sequences<Pairing>
    var onSessionProposal: ((SessionType.Proposal)->())?
    var onPairingApproved: ((PairingType.Settled)->())?
    
    init(relay: Relaying,
         crypto: Crypto,
         subscriber: WCSubscribing,
         sequences: Sequences<Pairing> = Sequences<Pairing>(),
         isController: Bool) {
        self.relayer = relay
        self.crypto = crypto
        self.wcSubscriber = subscriber
        self.sequences = sequences
        self.isController = isController
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
    
    func propose(_ params: ConnectParams) -> PairingType.Pending? {
        Logger.debug("Propose Pairing")
        guard let topic = generateTopic() else {
            Logger.debug("Could not generate topic")
            return nil
        }
        let privateKey = Crypto.X25519.generatePrivateKey()
        let publicKey = privateKey.publicKey.toHexString()
        crypto.set(privateKey: privateKey)
        let proposer = PairingType.Proposer(publicKey: publicKey, controller: isController)
        let uri = PairingType.UriParameters(topic: topic, publicKey: publicKey, controller: isController, relay: params.relay).absoluteString()!
        let signalParams = PairingType.Signal.Params(uri: uri)
        let signal = PairingType.Signal(params: signalParams)
        let permissions = getDefaultPermissions()
        let proposal = PairingType.Proposal(topic: topic, relay: params.relay, proposer: proposer, signal: signal, permissions: permissions, ttl: getDefaultTTL())
        let `self` = PairingType.Participant(publicKey: publicKey, metadata: params.metadata)
        let pending = PairingType.Pending(status: .proposed, topic: topic, relay: params.relay, self: `self`, proposal: proposal)
        sequences.create(topic: topic, sequenceState: .pending(pending))
        wcSubscriber.setSubscription(topic: topic)
        return pending
    }

    //MARK: - Private
    
    private func getDefaultTTL() -> Int {
        30 * Time.day
    }
    
    private func generateTopic() -> String? {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData.toHexString()
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    private func getDefaultPermissions() -> PairingType.ProposedPermissions {
        PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [PairingType.PayloadMethods.sessionPropose.rawValue]))
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
                handlePairingDelete(deleteParams, topic: subscriptionPayload.topic)
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
    
    private func handlePairingDelete(_ deleteParams: PairingType.DeleteParams, topic: String) {
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
        onPairingApproved?(settledPairing)
    }
}
