import Foundation
import Combine

final class PairingEngine {
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let crypto: Crypto
    private var isController: Bool
    var sequencesStore: PairingSequencesStore
    var onSessionProposal: ((SessionType.Proposal)->())?
    var onPairingApproved: ((PairingType.Settled, String)->())?
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: BaseLogger
    
    init(relay: WalletConnectRelaying,
         crypto: Crypto,
         subscriber: WCSubscribing,
         sequencesStore: PairingSequencesStore,
         isController: Bool,
         metadata: AppMetadata,
         logger: BaseLogger) {
        self.relayer = relay
        self.crypto = crypto
        self.wcSubscriber = subscriber
        self.metadata = metadata
        self.sequencesStore = sequencesStore
        self.isController = isController
        self.logger = logger
        setUpWCRequestHandling()
        restoreSubscriptions()
    }
    
    func respond(to proposal: PairingType.Proposal, completion: @escaping (Result<PairingType.Settled, Error>) -> Void) {
        let privateKey = Crypto.X25519.generatePrivateKey()
        let selfPublicKey = privateKey.publicKey.toHexString()
        
        let pendingPairing = PairingType.Pending(
            status: .responded,
            topic: proposal.topic,
            relay: proposal.relay,
            self: PairingType.Participant(publicKey: selfPublicKey),
            proposal: proposal)
        
        wcSubscriber.setSubscription(topic: proposal.topic)
        sequencesStore.create(topic: proposal.topic, sequenceState: .pending(pendingPairing))
        // settle on topic B
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(
            peerPublicKey: Data(hex: proposal.proposer.publicKey),
            privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        let selfParticipant = PairingType.Participant(publicKey: selfPublicKey, metadata: metadata)
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : selfPublicKey
        let settledPairing = PairingType.Settled(
            topic: settledTopic,
            relay: proposal.relay,
            self: selfParticipant,
            peer: PairingType.Participant(publicKey: proposal.proposer.publicKey),
            permissions: PairingType.Permissions(
                jsonrpc: proposal.permissions.jsonrpc,
                controller: Controller(publicKey: controllerKey)),
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil) // FIXME: State
        
                
        wcSubscriber.setSubscription(topic: settledTopic)
        sequencesStore.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledPairing))
        
        crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        crypto.set(privateKey: privateKey)
        
        // publish approve on topic A
        let approveParams = PairingType.ApproveParams(
            relay: proposal.relay,
            responder: selfParticipant,
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil) // FIXME: State
        let approvalPayload = ClientSynchJSONRPC(method: .pairingApprove, params: .pairingApprove(approveParams))
        
        relayer.publish(topic: proposal.topic, payload: approvalPayload) { [weak self] result in
            switch result {
            case .success:
                self?.wcSubscriber.removeSubscription(topic: proposal.topic)
                self?.logger.debug("Success on wc_pairingApprove")
                completion(.success(settledPairing))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func propose(_ params: ConnectParams) -> PairingType.Pending? {
        logger.debug("Propose Pairing")
        guard let topic = generateTopic() else {
            logger.debug("Could not generate topic")
            return nil
        }
        let privateKey = Crypto.X25519.generatePrivateKey()
        let publicKey = privateKey.publicKey.toHexString()
        let relay = RelayProtocolOptions(protocol: "waku", params: nil)
        crypto.set(privateKey: privateKey)
        let proposer = PairingType.Proposer(publicKey: publicKey, controller: isController)
        let uri = PairingType.UriParameters(topic: topic, publicKey: publicKey, controller: isController, relay: relay).absoluteString()!
        let signalParams = PairingType.Signal.Params(uri: uri)
        let signal = PairingType.Signal(params: signalParams)
        let permissions = getDefaultPermissions()
        let proposal = PairingType.Proposal(topic: topic, relay: relay, proposer: proposer, signal: signal, permissions: permissions, ttl: getDefaultTTL())
        let `self` = PairingType.Participant(publicKey: publicKey, metadata: metadata)
        let pending = PairingType.Pending(status: .proposed, topic: topic, relay: relay, self: `self`, proposal: proposal)
        sequencesStore.create(topic: topic, sequenceState: .pending(pending))
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
        wcSubscriber.onRequestSubscription = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.clientSynchJsonRpc.params {
            case .pairingApprove(let approveParams):
                handlePairingApprove(approveParams: approveParams, pendingTopic: subscriptionPayload.topic, reqestId: subscriptionPayload.clientSynchJsonRpc.id)
            case .pairingReject(_):
                fatalError("Not Implemented")
            case .pairingUpdate(_):
                fatalError("Not Implemented")
            case .pairingUpgrade(_):
                fatalError("Not Implemented")
            case .pairingDelete(let deleteParams):
                handlePairingDelete(deleteParams, topic: subscriptionPayload.topic)
            case .pairingPayload(let pairingPayload):
                self.handlePairingPayload(pairingPayload, for: subscriptionPayload.topic, requestId: subscriptionPayload.clientSynchJsonRpc.id)
            default:
                fatalError("not expected method type")
            }
        }
    }

    private func handlePairingPayload(_ payload: PairingType.PayloadParams, for topic: String, requestId: Int64) {
        logger.debug("Will handle pairing payload")
        guard let _ = sequencesStore.get(topic: topic) else {
            logger.error("Pairing for the topic: \(topic) does not exist")
            return
        }
        guard payload.request.method == PairingType.PayloadMethods.sessionPropose else {
            logger.error("Forbidden WCPairingPayload method")
            return
        }
        let sessionProposal = payload.request.params
        if let pairingAgreementKeys = crypto.getAgreementKeys(for: sessionProposal.signal.params.topic) {
            crypto.set(agreementKeys: pairingAgreementKeys, topic: sessionProposal.topic)
        }
        let response = JSONRPCResponse<Bool>(id: requestId, result: true)
        relayer.respond(topic: topic, payload: response) { [weak self] error in
            self?.onSessionProposal?(sessionProposal)
        }
    }
    
    private func handlePairingDelete(_ deleteParams: PairingType.DeleteParams, topic: String) {
        logger.debug("-------------------------------------")
        logger.debug("Paired client removed pairing - reason: \(deleteParams.reason.message), code: \(deleteParams.reason.code)")
        logger.debug("-------------------------------------")
        sequencesStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
    }
    
    private func handlePairingApprove(approveParams: PairingType.ApproveParams, pendingTopic: String, reqestId: Int64) {
        logger.debug("Responder Client approved pairing on topic: \(pendingTopic)")
        guard case let .pending(pairingPending) = sequencesStore.get(topic: pendingTopic) else {
                  logger.debug("Could not find pending pairing associated with topic \(pendingTopic)")
                  return
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
            self: PairingType.Participant(publicKey: selfPublicKey.toHexString()),
            peer: PairingType.Participant(publicKey: approveParams.responder.publicKey, metadata: approveParams.responder.metadata),
            permissions: PairingType.Permissions(
                jsonrpc: proposal.permissions.jsonrpc,
                controller: controller),
            expiry: approveParams.expiry,
            state: approveParams.state)
        
        sequencesStore.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledPairing))
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
        let response = JSONRPCResponse<Bool>(id: reqestId, result: true)
        relayer.respond(topic: proposal.topic, payload: response) { [weak self] error in
            self?.onPairingApproved?(settledPairing, pendingTopic)
        }
    }
    
    private func restoreSubscriptions() {
        relayer.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sequencesStore.getAll().map{$0.topic}
                topics.forEach{self.wcSubscriber.setSubscription(topic: $0)}
            }.store(in: &publishers)
    }
}
