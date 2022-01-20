import Foundation
import Combine
import WalletConnectUtils


final class PairingEngine {
    
    var onApprovalAcknowledgement: ((Pairing) -> Void)?
    var onSessionProposal: ((SessionProposal)->())?
    var onPairingApproved: ((Pairing, SessionPermissions, RelayProtocolOptions)->())?
    var onPairingUpdate: ((String, AppMetadata)->())?
    
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let crypto: CryptoStorageProtocol
    private let isController: Bool
    private let sequencesStore: PairingSequenceStorage
    private var appMetadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private var sessionPermissions: [String: SessionPermissions] = [:]
    private let topicInitializer: () -> String?
    
    init(relay: WalletConnectRelaying,
         crypto: CryptoStorageProtocol,
         subscriber: WCSubscribing,
         sequencesStore: PairingSequenceStorage,
         isController: Bool,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String? = String.generateTopic) {
        self.relayer = relay
        self.crypto = crypto
        self.wcSubscriber = subscriber
        self.appMetadata = metadata
        self.sequencesStore = sequencesStore
        self.isController = isController
        self.logger = logger
        self.topicInitializer = topicGenerator
        setUpWCRequestHandling()
        setupExpirationHandling()
        removeRespondedPendingPairings()
        restoreSubscriptions()
        
        relayer.onPairingResponse = { [weak self] in
            self?.handleReponse($0)
        }
    }
    
    func hasPairing(for topic: String) -> Bool {
        return sequencesStore.hasSequence(forTopic: topic)
    }
    
    func getSettledPairing(for topic: String) -> PairingSequence? {
        guard let pairing = try? sequencesStore.getSequence(forTopic: topic), pairing.isSettled else { return nil }
        return pairing
    }
    
    func getSettledPairings() -> [Pairing] {
        sequencesStore.getAll()
            .filter { $0.isSettled }
            .map { Pairing(topic: $0.topic, peer: $0.settled?.state?.metadata) }
    }
    
    func propose(permissions: SessionPermissions) -> WalletConnectURI? {
        guard let topic = topicInitializer() else {
            logger.debug("Could not generate topic")
            return nil
        }
        
        let publicKey = try! crypto.createX25519KeyPair()
        
        let relay = RelayProtocolOptions(protocol: "waku", params: nil)
        let uri = WalletConnectURI(topic: topic, publicKey: publicKey.hexRepresentation, isController: isController, relay: relay)
        let pendingPairing = PairingSequence.buildProposed(uri: uri)
        
        sequencesStore.setSequence(pendingPairing)
        wcSubscriber.setSubscription(topic: topic)
        sessionPermissions[topic] = permissions
        return uri
    }
    
    func approve(_ pairingURI: WalletConnectURI) throws {
        let proposal = PairingProposal.createFromURI(pairingURI)
        guard proposal.proposer.controller != isController else {
            throw WalletConnectError.internal(.unauthorizedMatchingController)
        }
        guard !hasPairing(for: proposal.topic) else {
            throw WalletConnectError.internal(.pairWithExistingPairingForbidden)
        }
        
        let selfPublicKey = try! crypto.createX25519KeyPair()
        let agreementKeys = try! crypto.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposal.proposer.publicKey)
        
        let settledTopic = agreementKeys.derivedTopic()
        let pendingPairing = PairingSequence.buildResponded(proposal: proposal, agreementKeys: agreementKeys)
        let settledPairing = PairingSequence.buildPreSettled(proposal: proposal, agreementKeys: agreementKeys)
        
        wcSubscriber.setSubscription(topic: proposal.topic)
        sequencesStore.setSequence(pendingPairing)
        wcSubscriber.setSubscription(topic: settledTopic)
        sequencesStore.setSequence(settledPairing)
        
        try? crypto.setAgreementSecret(agreementKeys, topic: settledTopic)
        
        let approval = PairingType.ApprovalParams(
            relay: proposal.relay,
            responder: PairingParticipant(publicKey: selfPublicKey.hexRepresentation),
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil) // Should this be removed?
        
        relayer.request(.wcPairingApprove(approval), onTopic: proposal.topic)
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.debug("Could not find pairing to ping for topic \(topic)")
            return
        }
        relayer.request(.wcPairingPing, onTopic: topic) { [unowned self] result in
            switch result {
            case .success(_):
                logger.debug("Did receive ping response")
                completion(.success(()))
            case .failure(let error):
                logger.debug("error: \(error)")
            }
        }
    }
    
    //MARK: - Private
    
    private func acknowledgeApproval(pendingTopic: String) throws {
        guard
            let pendingPairing = try sequencesStore.getSequence(forTopic: pendingTopic),
            case .responded(let settledTopic) = pendingPairing.pending?.status,
            var settledPairing = try sequencesStore.getSequence(forTopic: settledTopic)
        else { return }
        
        settledPairing.settled?.status = .acknowledged
        sequencesStore.setSequence(settledPairing)
        wcSubscriber.removeSubscription(topic: pendingTopic)
        sequencesStore.delete(topic: pendingTopic)
        
        let pairing = Pairing(topic: settledPairing.topic, peer: nil)
        onApprovalAcknowledgement?(pairing)
        update(topic: settledPairing.topic)
        logger.debug("Success on wc_pairingApprove - settled topic - \(settledTopic)")
        logger.debug("Pairing Success")
    }
    
    private func update(topic: String) {
        guard var pairing = try? sequencesStore.getSequence(forTopic: topic) else {
            logger.debug("Could not find pairing for topic \(topic)")
            return
        }
        relayer.request(.wcPairingUpdate(PairingType.UpdateParams(state: PairingState(metadata: appMetadata))), onTopic: topic) { [unowned self] result in
            switch result {
            case .success(_):
                pairing.settled?.state?.metadata = appMetadata
                sequencesStore.setSequence(pairing)
            case .failure(let error):
                logger.error(error)
            }
        }
    }

    private func setUpWCRequestHandling() {
        wcSubscriber.onReceivePayload = { [unowned self] subscriptionPayload in
            let requestId = subscriptionPayload.wcRequest.id
            let topic = subscriptionPayload.topic
            switch subscriptionPayload.wcRequest.params {
            case .pairingApprove(let approveParams):
                handlePairingApprove(approveParams: approveParams, pendingPairingTopic: topic, requestId: requestId)
            case .pairingUpdate(let updateParams):
                handlePairingUpdate(params: updateParams, topic: topic, requestId: requestId)
            case .pairingPayload(let pairingPayload):
                self.handlePairingPayload(pairingPayload, for: topic, requestId: requestId)
            case .pairingPing(_):
                self.handlePairingPing(topic: topic, requestId: requestId)
            default:
                logger.warn("Warning: Pairing Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }
    }
    
    private func handlePairingUpdate(params:  PairingType.UpdateParams,topic: String, requestId: Int64) {
        guard var pairing = try? sequencesStore.getSequence(forTopic: topic) else {
            logger.debug("Could not find pairing for topic \(topic)")
            return
        }
        guard pairing.peerIsController else {
            let error = WalletConnectError.unauthrorized(.unauthorizedUpdateRequest)
            logger.error(error)
            respond(error: error, requestId: requestId, topic: topic)
            return
        }
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [unowned self] error in
            if let error = error {
                logger.error(error)
            } else {
                pairing.settled?.state = params.state
                sequencesStore.setSequence(pairing)
                onPairingUpdate?(topic, params.state.metadata)
            }
        }
    }
    
    private func handlePairingPing(topic: String, requestId: Int64) {
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { error in
            //todo
        }
    }

    private func handlePairingPayload(_ payload: PairingType.PayloadParams, for topic: String, requestId: Int64) {
        logger.debug("Will handle pairing payload")
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.error("Pairing for the topic: \(topic) does not exist")
            return
        }
        guard payload.request.method == PairingType.PayloadMethods.sessionPropose else {
            logger.error("Forbidden WCPairingPayload method")
            return
        }
        let sessionProposal = payload.request.params
        if let pairingAgreementSecret = try? crypto.getAgreementSecret(for: sessionProposal.signal.params.topic) {
            try? crypto.setAgreementSecret(pairingAgreementSecret, topic: sessionProposal.topic)
        }
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [weak self] error in
            self?.onSessionProposal?(sessionProposal)
        }
    }
    
    private func handlePairingApprove(approveParams: PairingType.ApprovalParams, pendingPairingTopic: String, requestId: Int64) {
        logger.debug("Responder Client approved pairing on topic: \(pendingPairingTopic)")
        guard let pairing = try? sequencesStore.getSequence(forTopic: pendingPairingTopic), let pendingPairing = pairing.pending else {
            return
        }
        
        let agreementKeys = try! crypto.performKeyAgreement(selfPublicKey: try! pairing.getPublicKey(), peerPublicKey: approveParams.responder.publicKey)
        
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        try? crypto.setAgreementSecret(agreementKeys, topic: settledTopic)
        let proposal = pendingPairing.proposal
        let settledPairing = PairingSequence.buildAcknowledged(approval: approveParams, proposal: proposal, agreementKeys: agreementKeys)
        
        sequencesStore.setSequence(settledPairing)
        sequencesStore.delete(topic: pendingPairingTopic)
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
        
        guard let permissions = sessionPermissions[pendingPairingTopic] else {
            logger.debug("Cound not find permissions for pending topic: \(pendingPairingTopic)")
            return
        }
        sessionPermissions[pendingPairingTopic] = nil
        
        // TODO: Move JSON-RPC responding to networking layer
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: proposal.topic, response: JsonRpcResponseTypes.response(response)) { [weak self] error in
            if let error = error {
                self?.logger.error("Could not respond with error: \(error)")
            }
        }
        
        onPairingApproved?(Pairing(topic: settledPairing.topic, peer: nil), permissions, settledPairing.relay)
    }
    
    private func removeRespondedPendingPairings() {
        sequencesStore.getAll().forEach {
            if let pending = $0.pending, pending.isResponded {
                sequencesStore.delete(topic: $0.topic)
            }
        }
    }
    
    private func restoreSubscriptions() {
        relayer.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sequencesStore.getAll()
                    .map{$0.topic}
                topics.forEach{self.wcSubscriber.setSubscription(topic: $0)}
            }.store(in: &publishers)
    }
    
    private func setupExpirationHandling() {
        sequencesStore.onSequenceExpiration = { [weak self] topic, publicKey in
            self?.crypto.deletePrivateKey(for: publicKey)
            self?.crypto.deleteAgreementSecret(for: topic)
        }
    }
    
    private func respond(error: WalletConnectError, requestId: Int64, topic: String) {
        let jsonrpcError = JSONRPCErrorResponse.Error(code: error.code, message: error.description)
        let response = JSONRPCErrorResponse(id: requestId, error: jsonrpcError)
        relayer.respond(topic: topic, response: .error(response)) { [weak self] responseError in
            if let responseError = responseError {
                self?.logger.error("Could not respond with error: \(responseError)")
            } else {
                self?.logger.debug("successfully responded with error")
            }
        }
    }
    
    private func handleReponse(_ response: WCResponse) {
        switch response.requestParams {
        case .pairingApprove:
            try? acknowledgeApproval(pendingTopic: response.topic)
        default:
            break
        }
    }
}
