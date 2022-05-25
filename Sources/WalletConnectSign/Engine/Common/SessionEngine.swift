import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS


final class SessionEngine {
    var onSessionRequest: ((Request)->())?
    var onSessionResponse: ((Response)->())?
    var onSessionSettle: ((Session)->())?
    var onSessionRejected: ((String, SessionType.Reason)->())?
    var onSessionDelete: ((String, SessionType.Reason)->())?
    var onEventReceived: ((String, Session.Event, Blockchain?)->())?
    
    var settlingProposal: SessionProposal?
    
    private let sessionStore: WCSessionStorage
    private let pairingStore: WCPairingStorage
    private let sessionToPairingTopic: KeyValueStore<String>
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let topicInitializer: () -> String

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         pairingStore: WCPairingStorage,
         sessionStore: WCSessionStorage,
         sessionToPairingTopic: KeyValueStore<String>,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String = String.generateTopic) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.metadata = metadata
        self.sessionStore = sessionStore
        self.pairingStore = pairingStore
        self.sessionToPairingTopic = sessionToPairingTopic
        self.logger = logger
        self.topicInitializer = topicGenerator
        setUpWCRequestHandling()
        setupExpirationHandling()
        restoreSubscriptions()
        
        networkingInteractor.onResponse = { [weak self] in
            self?.handleResponse($0)
        }
    }
    
    func setSubscription(topic: String) {
        Task { try? await networkingInteractor.subscribe(topic: topic) }
    }
    
    func hasSession(for topic: String) -> Bool {
        return sessionStore.hasSession(forTopic: topic)
    }
    
    func getSessions() -> [Session] {
        sessionStore.getAll().map{$0.publicRepresentation()}
    }
    
    func settle(topic: String, proposal: SessionProposal, namespaces: [String: SessionNamespace]) throws {
        let agreementKeys = try! kms.getAgreementSecret(for: topic)!
        let selfParticipant = Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata)
        
        let expectedExpiryTimeStamp = Date().addingTimeInterval(TimeInterval(WCSession.defaultTimeToLive))
        guard let relay = proposal.relays.first else {return}
        let settleParams = SessionType.SettleParams(
            relay: relay,
            controller: selfParticipant,
            namespaces: namespaces,
            expiry: Int64(expectedExpiryTimeStamp.timeIntervalSince1970))//todo - test expiration times
        let session = WCSession(
            topic: topic,
            selfParticipant: selfParticipant,
            peerParticipant: proposal.proposer,
            settleParams: settleParams,
            acknowledged: false)
        logger.debug("Sending session settle request")
        Task { try? await networkingInteractor.subscribe(topic: topic) }
        sessionStore.setSession(session)
        networkingInteractor.request(.wcSessionSettle(settleParams), onTopic: topic)
        onSessionSettle?(session.publicRepresentation())
    }
    
    func delete(topic: String, reason: Reason) async throws {
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        try await networkingInteractor.request(.wcSessionDelete(reason.internalRepresentation()), onTopic: topic)
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard sessionStore.hasSession(forTopic: topic) else {
            logger.debug("Could not find session to ping for topic \(topic)")
            return
        }
        networkingInteractor.requestPeerResponse(.wcSessionPing, onTopic: topic) { [unowned self] result in
            switch result {
            case .success(_):
                logger.debug("Did receive ping response")
                completion(.success(()))
            case .failure(let error):
                logger.debug("error: \(error)")
            }
        }
    }
    
    func request(_ request: Request) async throws {
        print("will request on session topic: \(request.topic)")
        guard let session = sessionStore.getSession(forTopic: request.topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(request.topic)")
            return // TODO: Marked to review on developer facing error cases
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            throw WalletConnectError.invalidPermissions
        }
        let chainRequest = SessionType.RequestParams.Request(method: request.method, params: request.params)
        let sessionRequestParams = SessionType.RequestParams(request: chainRequest, chainId: request.chainId)
        try await networkingInteractor.request(.wcSessionRequest(sessionRequestParams), onTopic: request.topic)
    }
    
    func respondSessionRequest(topic: String, response: JsonRpcResult) {
        guard sessionStore.hasSession(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        networkingInteractor.respond(topic: topic, response: response) { [weak self] error in
            if let error = error {
                self?.logger.debug("Could not send session payload, error: \(error.localizedDescription)")
            } else {
                self?.logger.debug("Sent Session Request Response")
            }
        }
    }
    
    func emit(topic: String, event: SessionType.EventParams.Event, chainId: Blockchain) async throws {
        guard let session = sessionStore.getSession(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        guard session.hasPermission(forEvent: event.name, onChain: chainId) else {
            throw WalletConnectError.invalidEvent
        }
        let params = SessionType.EventParams(event: event, chainId: chainId)
        try await networkingInteractor.request(.wcSessionEvent(params), onTopic: topic)
    }

    //MARK: - Private
    
    private func setUpWCRequestHandling() {
        networkingInteractor.wcRequestPublisher.sink  { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .sessionSettle(let settleParams):
                onSessionSettle(payload: subscriptionPayload, settleParams: settleParams)
            case .sessionDelete(let deleteParams):
                onSessionDelete(subscriptionPayload, deleteParams: deleteParams)
            case .sessionRequest(let sessionRequestParams):
                onSessionRequest(subscriptionPayload, payloadParams: sessionRequestParams)
            case .sessionPing(_):
                onSessionPing(subscriptionPayload)
            case .sessionEvent(let eventParams):
                onSessionEvent(subscriptionPayload, eventParams: eventParams)
            default:
                return
            }
        }.store(in: &publishers)
    }
    
    private func onSessionSettle(payload: WCRequestSubscriptionPayload, settleParams: SessionType.SettleParams) {
        logger.debug("Did receive session settle request")
        guard let proposedNamespaces = settlingProposal?.requiredNamespaces else {
            // TODO: respond error
            return
        }
        settlingProposal = nil
        let sessionNamespaces = settleParams.namespaces
        do {
            try Namespace.validate(proposedNamespaces)
            try Namespace.validate(sessionNamespaces)
            try Namespace.validateApproved(sessionNamespaces, against: proposedNamespaces)
        } catch {
            // TODO: respond error
            return
        }
                
        let topic = payload.topic
        
        let agreementKeys = try! kms.getAgreementSecret(for: topic)!
        
        let selfParticipant = Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata)
        
        if let pairingTopic = try? sessionToPairingTopic.get(key: topic) {
            updatePairingMetadata(topic: pairingTopic, metadata: settleParams.controller.metadata)
        }
        
        let session = WCSession(
            topic: topic,
            selfParticipant: selfParticipant,
            peerParticipant: settleParams.controller,
            settleParams: settleParams,
            acknowledged: true)
        sessionStore.setSession(session)
        networkingInteractor.respondSuccess(for: payload)
        onSessionSettle?(session.publicRepresentation())
    }
    
    private func onSessionDelete(_ payload: WCRequestSubscriptionPayload, deleteParams: SessionType.DeleteParams) {
        let topic = payload.topic
        guard sessionStore.hasSession(forTopic: topic) else {
            networkingInteractor.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: topic))
            return
        }
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
        networkingInteractor.respondSuccess(for: payload)
        onSessionDelete?(topic, deleteParams)
    }
    
    private func onSessionRequest(_ payload: WCRequestSubscriptionPayload, payloadParams: SessionType.RequestParams) {
        let topic = payload.topic
        let jsonRpcRequest = JSONRPCRequest<AnyCodable>(id: payload.wcRequest.id, method: payloadParams.request.method, params: payloadParams.request.params)
        let request = Request(
            id: jsonRpcRequest.id,
            topic: topic,
            method: jsonRpcRequest.method,
            params: jsonRpcRequest.params,
            chainId: payloadParams.chainId)
        
        guard let session = sessionStore.getSession(forTopic: topic) else {
            networkingInteractor.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: topic))
            return
        }
        let chain = request.chainId
        guard session.hasNamespace(for: chain) else {
            networkingInteractor.respondError(for: payload, reason: .unauthorizedTargetChain(chain.absoluteString))
            return
        }
        guard session.hasPermission(forMethod: request.method, onChain: chain) else {
            networkingInteractor.respondError(for: payload, reason: .unauthorizedMethod(request.method))
            return
        }
        onSessionRequest?(request)
    }
    
    private func onSessionPing(_ payload: WCRequestSubscriptionPayload) {
        networkingInteractor.respondSuccess(for: payload)
    }
    
    private func onSessionEvent(_ payload: WCRequestSubscriptionPayload, eventParams: SessionType.EventParams) {
        let event = eventParams.event
        let topic = payload.topic
        guard let session = sessionStore.getSession(forTopic: topic) else {
            networkingInteractor.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        guard
            session.peerIsController,
            session.hasPermission(forEvent: event.name, onChain: eventParams.chainId)
        else {
            networkingInteractor.respondError(for: payload, reason: .unauthorizedEvent(event.name))
            return
        }
        networkingInteractor.respondSuccess(for: payload)
        onEventReceived?(topic, event.publicRepresentation(), eventParams.chainId)
    }

    private func setupExpirationHandling() {
        sessionStore.onSessionExpiration = { [weak self] session in
            self?.kms.deletePrivateKey(for: session.selfParticipant.publicKey)
            self?.kms.deleteAgreementSecret(for: session.topic)
        }
    }
    
    private func restoreSubscriptions() {
        networkingInteractor.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sessionStore.getAll().map{$0.topic}
                topics.forEach{ topic in Task { try? await networkingInteractor.subscribe(topic: topic) } }
            }.store(in: &publishers)
    }
    
    private func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionSettle:
            handleSessionSettleResponse(topic: response.topic, result: response.result)
        case .sessionRequest:
            let response = Response(topic: response.topic, chainId: response.chainId, result: response.result)
            onSessionResponse?(response)
        default:
            break
        }
    }
    
    func handleSessionSettleResponse(topic: String, result: JsonRpcResult) {
        guard let session = sessionStore.getSession(forTopic: topic) else {return}
        switch result {
        case .response:
            logger.debug("Received session settle response")
            guard var session = sessionStore.getSession(forTopic: topic) else {return}
            session.acknowledge()
            sessionStore.setSession(session)
        case .error(let error):
            logger.error("Error - session rejected, Reason: \(error)")
            networkingInteractor.unsubscribe(topic: topic)
            sessionStore.delete(topic: topic)
            kms.deleteAgreementSecret(for: topic)
            kms.deletePrivateKey(for: session.publicKey!)
        }
    }
    
    private func updatePairingMetadata(topic: String, metadata: AppMetadata) {
        guard var pairing = pairingStore.getPairing(forTopic: topic) else {return}
        pairing.peerMetadata = metadata
        pairingStore.setPairing(pairing)
    }
}
