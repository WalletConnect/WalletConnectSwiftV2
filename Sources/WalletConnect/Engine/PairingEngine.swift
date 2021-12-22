import Foundation
import Combine
import WalletConnectUtils
import CryptoKit

final class PairingEngine {
    
    var onApprovalAcknowledgement: ((Pairing) -> Void)?
    var onSessionProposal: ((SessionType.Proposal)->())?
    var onPairingApproved: ((Pairing, SessionType.Permissions, RelayProtocolOptions)->())?
    var onPairingUpdate: ((String, AppMetadata)->())?
    
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let crypto: CryptoStorageProtocol
    private let isController: Bool
    private let sequencesStore: PairingSequenceStorage
    private var appMetadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private var sessionPermissions: [String: SessionType.Permissions] = [:]
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
        
        relayer.onPairingApproveResponse = { [weak self] in
            try? self?.acknowledgeApproval(pendingTopic: $0)
        }
        
        // TODO: Bind on response
//        relayer.onResponse = { [weak self] in
//            print($0.topic)
//        }
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
    
    func propose(permissions: SessionType.Permissions) -> WalletConnectURI? {
        guard let topic = topicInitializer() else {
            logger.debug("Could not generate topic")
            return nil
        }
        
        let privateKey = crypto.makePrivateKey()
        try! crypto.set(privateKey: privateKey) // TODO: Handle error
        let publicKey = privateKey.publicKey.hexRepresentation
        
        let relay = RelayProtocolOptions(protocol: "waku", params: nil)
        let uri = WalletConnectURI(topic: topic, publicKey: publicKey, isController: isController, relay: relay)
        let pendingPairing = PairingSequence.buildProposedFromURI(uri)
        
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
        
        let privateKey = crypto.makePrivateKey()
        try? crypto.set(privateKey: privateKey) // TODO: Handle error
        let selfPublicKey = privateKey.publicKey.hexRepresentation
        
        let agreementKeys = try! Crypto.generateAgreementKeys(
            peerPublicKey: Data(hex: proposal.proposer.publicKey),
            privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        
        let selfParticipant = PairingType.Participant(publicKey: selfPublicKey)
        
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : selfPublicKey
        
        let pendingPairing = PairingSequence(
            topic: proposal.topic,
            relay: proposal.relay,
            selfParticipant: selfParticipant,
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(Time.day)),
            pendingState: PairingSequence.Pending(
                proposal: proposal,
                status: .responded(settledTopic)))
        
        let settled = PairingSequence.Settled(
            peer: PairingType.Participant(publicKey: proposal.proposer.publicKey),
            permissions: PairingType.Permissions(
                jsonrpc: proposal.permissions.jsonrpc,
                controller: Controller(publicKey: controllerKey)),
            state: nil,
            status: .preSettled)
        let settledPairing = PairingSequence(
            topic: settledTopic,
            relay: proposal.relay,
            selfParticipant: selfParticipant,
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(proposal.ttl)),
            settledState: settled)
        
        wcSubscriber.setSubscription(topic: proposal.topic)
        sequencesStore.setSequence(pendingPairing)
        
        wcSubscriber.setSubscription(topic: settledTopic)
        sequencesStore.setSequence(settledPairing)
        
        try? crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        
        
        // publish approve on topic A
        let approveParams = PairingType.ApproveParams(
            relay: proposal.relay,
            responder: selfParticipant,
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil) // FIXME: State
        let approvalPayload = WCRequest(method: .pairingApprove, params: .pairingApprove(approveParams))
        
        relayer.request(topic: proposal.topic, payload: approvalPayload) { [weak self] result in
            switch result {
            case .success:
                self?.logger.debug("Success on wc_pairingApprove - settled topic - \(settledTopic)")
                self?.logger.debug("Pairing Success")
            case .failure:
                break
            }
        }
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.debug("Could not find pairing to ping for topic \(topic)")
            return
        }
        let request = WCRequest(method: .pairingPing, params: .pairingPing(PairingType.PingParams()))
        relayer.request(topic: topic, payload: request) { [unowned self] result in
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
    }
    
    private func update(topic: String) {
        guard var pairing = try? sequencesStore.getSequence(forTopic: topic) else {
            logger.debug("Could not find pairing for topic \(topic)")
            return
        }
        let params = WCRequest.Params.pairingUpdate(PairingType.UpdateParams(state: PairingType.State(metadata: appMetadata)))
        let request = WCRequest(method: .pairingUpdate, params: params)
        relayer.request(topic: topic, payload: request) { [unowned self] result in
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
        if let pairingAgreementKeys = crypto.getAgreementKeys(for: sessionProposal.signal.params.topic) {
            try? crypto.set(agreementKeys: pairingAgreementKeys, topic: sessionProposal.topic)
        }
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [weak self] error in
            self?.onSessionProposal?(sessionProposal)
        }
    }
    
    private func handlePairingApprove(approveParams: PairingType.ApproveParams, pendingPairingTopic: String, requestId: Int64) {
        logger.debug("Responder Client approved pairing on topic: \(pendingPairingTopic)")
        guard let pendingPairing = try? sequencesStore.getSequence(forTopic: pendingPairingTopic), let pairingPending = pendingPairing.pending else {
            return
        }
        let selfPublicKey = Data(hex: pendingPairing.selfParticipant.publicKey)
        let pubKey = try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: selfPublicKey)
        let privateKey = try! crypto.getPrivateKey(for: pubKey)!
        let peerPublicKey = Data(hex: approveParams.responder.publicKey)
        let agreementKeys = try! Crypto.generateAgreementKeys(peerPublicKey: peerPublicKey, privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        try? crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        let proposal = pairingPending.proposal
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : peerPublicKey.toHexString()
        let controller = Controller(publicKey: controllerKey)
        
        let peer = PairingType.Participant(publicKey: approveParams.responder.publicKey)
        let settledPairing = PairingSequence(
            topic: settledTopic,
            relay: approveParams.relay,
            selfParticipant: PairingType.Participant(publicKey: selfPublicKey.toHexString()),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(approveParams.expiry)),
            settledState: PairingSequence.Settled(
                peer: peer,
                permissions: PairingType.Permissions(
                    jsonrpc: proposal.permissions.jsonrpc,
                    controller: controller),
                state: approveParams.state,
                status: .acknowledged))
        sequencesStore.setSequence(settledPairing)
        sequencesStore.delete(topic: pendingPairingTopic)
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
        
        let pairing = Pairing(topic: settledPairing.topic, peer: nil) // FIXME: peer?
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
        
        onPairingApproved?(pairing, permissions, settledPairing.relay)
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
            self?.crypto.deleteAgreementKeys(for: topic)
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
}
