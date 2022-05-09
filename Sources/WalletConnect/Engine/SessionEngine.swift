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
        networkingInteractor.subscribe(topic: topic)
    }
    
    func hasSession(for topic: String) -> Bool {
        return sessionStore.hasSession(forTopic: topic)
    }
    
    func getAcknowledgedSessions() -> [Session] {
        sessionStore.getAcknowledgedSessions().map{$0.publicRepresentation()}
    }
    
    func delete(topic: String, reason: Reason) async throws {
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
        try await networkingInteractor.request(.wcSessionDelete(reason.internalRepresentation()), onTopic: topic)
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
    
    func request(params: Request) async throws {
        print("will request on session topic: \(params.topic)")
        guard sessionStore.hasSession(forTopic: params.topic) else {
            logger.debug("Could not find session for topic \(params.topic)")
            return
        }
        let request = SessionType.RequestParams.Request(method: params.method, params: params.params)
        let sessionRequestParams = SessionType.RequestParams(request: request, chainId: params.chainId)
        try await networkingInteractor.request(.wcSessionRequest(sessionRequestParams), onTopic: params.topic)
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
                self?.logger.debug("Sent Session Payload Response")
            }
        }
    }
    
    func emit(topic: String, event: SessionType.EventParams.Event, chainId: Blockchain, completion: ((Error?)->())?) {
        guard let session = sessionStore.getSession(forTopic: topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        let params = SessionType.EventParams(event: event, chainId: chainId)
        do {
            guard session.hasNamespace(for: chainId, event: event.name) else {
                throw WalletConnectError.invalidEvent
            }
            networkingInteractor.request(.wcSessionEvent(params), onTopic: topic)
        } catch let error as WalletConnectError {
            logger.error(error)
            completion?(error)
        } catch {}
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

    func settle(topic: String, proposal: SessionProposal, accounts: Set<Account>, namespaces: Set<Namespace>) {
        let agreementKeys = try! kms.getAgreementSecret(for: topic)!
        
        let selfParticipant = Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata)
        
        let expectedExpiryTimeStamp = Date().addingTimeInterval(TimeInterval(WCSession.defaultTimeToLive))
        guard let relay = proposal.relays.first else {return}
        let settleParams = SessionType.SettleParams(
            relay: relay,
            controller: selfParticipant, accounts: accounts,
            namespaces: namespaces,
            expiry: Int64(expectedExpiryTimeStamp.timeIntervalSince1970))//todo - test expiration times
        let session = WCSession(
            topic: topic,
            selfParticipant: selfParticipant,
            peerParticipant: proposal.proposer,
            settleParams: settleParams,
            acknowledged: false)
        
        networkingInteractor.subscribe(topic: topic)
        sessionStore.setSession(session)
        
        networkingInteractor.request(.wcSessionSettle(settleParams), onTopic: topic)
    }

    private func onSessionSettle(payload: WCRequestSubscriptionPayload, settleParams: SessionType.SettleParams) {
        logger.debug("Did receive session settle request")
        let topic = payload.topic
        
        let agreementKeys = try! kms.getAgreementSecret(for: topic)!
        
        let selfParticipant = Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata)
        
        if let pairingTopic = try? sessionToPairingTopic.get(key: topic) {
            updatePairingMetadata(topic: pairingTopic, metadata: settleParams.controller.metadata)
        }
        
        let session = WCSession(topic: topic,
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
        if let chain = request.chainId {
            guard session.hasNamespace(for: chain) else {
                networkingInteractor.respondError(for: payload, reason: .unauthorizedTargetChain(chain.absoluteString))
                return
            }
            guard session.hasNamespace(for: chain, method: request.method) else {
                networkingInteractor.respondError(for: payload, reason: .unauthorizedMethod(request.method))
                return
            }
        } else {
            guard session.hasNamespace(for: nil, method: request.method) else {
                networkingInteractor.respondError(for: payload, reason: .unauthorizedMethod(request.method))
                return
            }
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
        guard session.peerIsController,
              session.hasNamespace(for: eventParams.chainId, event: event.name) else {
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
                topics.forEach{networkingInteractor.subscribe(topic: $0)}
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
            guard var session = sessionStore.getSession(forTopic: topic) else {return}
            session.acknowledge()
            sessionStore.setSession(session)
            onSessionSettle?(session.publicRepresentation())
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
