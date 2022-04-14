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
    var onEventReceived: ((String, Session.Event)->())?
    
    private let sessionStore: WCSessionStorage
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let topicInitializer: () -> String

    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         subscriber: WCSubscribing,
         sessionStore: WCSessionStorage,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String = String.generateTopic) {
        self.relayer = relay
        self.kms = kms
        self.metadata = metadata
        self.wcSubscriber = subscriber
        self.sessionStore = sessionStore
        self.logger = logger
        self.topicInitializer = topicGenerator
        setUpWCRequestHandling()
        setupExpirationHandling()
        restoreSubscriptions()
        
        relayer.onResponse = { [weak self] in
            self?.handleResponse($0)
        }
    }
    
    func setSubscription(topic: String) {
        wcSubscriber.setSubscription(topic: topic)
    }
    
    func hasSession(for topic: String) -> Bool {
        return sessionStore.hasSession(forTopic: topic)
    }
    
    func getAcknowledgedSessions() -> [Session] {
        sessionStore.getAcknowledgedSessions().map{$0.publicRepresentation()}
    }
    
    func delete(topic: String, reason: Reason) {
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        sessionStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
        relayer.request(.wcSessionDelete(SessionType.DeleteParams(reason: reason.internalRepresentation())), onTopic: topic)
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard sessionStore.hasSession(forTopic: topic) else {
            logger.debug("Could not find session to ping for topic \(topic)")
            return
        }
        relayer.request(.wcSessionPing, onTopic: topic) { [unowned self] result in
            switch result {
            case .success(_):
                logger.debug("Did receive ping response")
                completion(.success(()))
            case .failure(let error):
                logger.debug("error: \(error)")
            }
        }
    }
    
    func request(params: Request) {
        print("will request on session topic: \(params.topic)")
        guard sessionStore.hasSession(forTopic: params.topic) else {
            logger.debug("Could not find session for topic \(params.topic)")
            return
        }
        let request = SessionType.RequestParams.Request(method: params.method, params: params.params)
        let sessionRequestParams = SessionType.RequestParams(request: request, chainId: params.chainId)
        let sessionRequest = WCRequest(id: params.id, method: .sessionRequest, params: .sessionRequest(sessionRequestParams))
        relayer.request(topic: params.topic, payload: sessionRequest) { [weak self] result in
            switch result {
            case .success(_):
                self?.logger.debug("Did receive session payload response")
            case .failure(let error):
                self?.logger.debug("error: \(error)")
            }
        }
    }
    
    func respondSessionRequest(topic: String, response: JsonRpcResult) {
        guard sessionStore.hasSession(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        relayer.respond(topic: topic, response: response) { [weak self] error in
            if let error = error {
                self?.logger.debug("Could not send session payload, error: \(error.localizedDescription)")
            } else {
                self?.logger.debug("Sent Session Payload Response")
            }
        }
    }
    
    func notify(topic: String, params: Session.Event, completion: ((Error?)->())?) {
        guard let session = sessionStore.getSession(forTopic: topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        do {
            let params = SessionType.EventParams(event: SessionType.EventParams.Event(type: params.type, data: params.data), chainId: params.chainId)
            try validateEvents(session: session, params: params)
            relayer.request(.wcSessionEvent(params), onTopic: topic) { result in
                switch result {
                case .success(_):
                    completion?(nil)
                case .failure(let error):
                    completion?(error)
                }
            }
        } catch let error as WalletConnectError {
            logger.error(error)
            completion?(error)
        } catch {}
    }

    //MARK: - Private
    
    private func setUpWCRequestHandling() {
        wcSubscriber.onReceivePayload = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .sessionSettle(let settleParams):
                wcSessionSettle(payload: subscriptionPayload, settleParams: settleParams)
            case .sessionDelete(let deleteParams):
                wcSessionDelete(subscriptionPayload, deleteParams: deleteParams)
            case .sessionRequest(let sessionRequestParams):
                wcSessionRequest(subscriptionPayload, payloadParams: sessionRequestParams)
            case .sessionPing(_):
                wcSessionPing(subscriptionPayload)
            case .sessionEvent(let eventParams):
                wcSessionEvent(subscriptionPayload, eventParams: eventParams)
            default:
                logger.warn("Warning: Session Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }
    }

    func settle(topic: String, proposal: SessionProposal, accounts: Set<Account>) {
        let agreementKeys = try! kms.getAgreementSecret(for: topic)!
        
        let selfParticipant = Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata)
        
        let expectedExpiryTimeStamp = Date().addingTimeInterval(TimeInterval(WCSession.defaultTimeToLive))
        guard let relay = proposal.relays.first else {return}
        let settleParams = SessionType.SettleParams(
            relay: relay,
            controller: selfParticipant, accounts: accounts,
            methods: proposal.methods,
            events: proposal.events,
            expiry: Int64(expectedExpiryTimeStamp.timeIntervalSince1970))//todo - test expiration times
        let session = WCSession(
            topic: topic,
            selfParticipant: selfParticipant,
            peerParticipant: proposal.proposer,
            settleParams: settleParams,
            acknowledged: false)
        
        wcSubscriber.setSubscription(topic: topic)
        sessionStore.setSession(session)
        
        relayer.request(.wcSessionSettle(settleParams), onTopic: topic)
    }
    
    private func wcSessionSettle(payload: WCRequestSubscriptionPayload, settleParams: SessionType.SettleParams) {
        logger.debug("Did receive session settle request")
        let topic = payload.topic
        
        let agreementKeys = try! kms.getAgreementSecret(for: topic)!
        
        let selfParticipant = Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata)
        
        let session = WCSession(topic: topic,
                                      selfParticipant: selfParticipant,
                                      peerParticipant: settleParams.controller,
                                      settleParams: settleParams,
                                      acknowledged: true)
        
        sessionStore.setSession(session)
        relayer.respondSuccess(for: payload)
        onSessionSettle?(session.publicRepresentation())
    }
    
    private func wcSessionDelete(_ payload: WCRequestSubscriptionPayload, deleteParams: SessionType.DeleteParams) {
        let topic = payload.topic
        guard sessionStore.hasSession(forTopic: topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: topic))
            return
        }
        sessionStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
        relayer.respondSuccess(for: payload)
        onSessionDelete?(topic, deleteParams.reason)
    }
    
    private func wcSessionRequest(_ payload: WCRequestSubscriptionPayload, payloadParams: SessionType.RequestParams) {
        let topic = payload.topic
        let jsonRpcRequest = JSONRPCRequest<AnyCodable>(id: payload.wcRequest.id, method: payloadParams.request.method, params: payloadParams.request.params)
        let request = Request(
            id: jsonRpcRequest.id,
            topic: topic,
            method: jsonRpcRequest.method,
            params: jsonRpcRequest.params,
            chainId: payloadParams.chainId)
        
        guard let session = sessionStore.getSession(forTopic: topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: topic))
            return
        }
        if let chainId = request.chainId {
            guard session.hasPermission(forChain: chainId) else {
                relayer.respondError(for: payload, reason: .unauthorizedTargetChain(chainId))
                return
            }
        }
        guard session.hasPermission(forMethod: request.method) else {
            relayer.respondError(for: payload, reason: .unauthorizedRPCMethod(request.method))
            return
        }
        onSessionRequest?(request)
    }
    
    private func wcSessionPing(_ payload: WCRequestSubscriptionPayload) {
        relayer.respondSuccess(for: payload)
    }
    
    private func wcSessionEvent(_ payload: WCRequestSubscriptionPayload, eventParams: SessionType.EventParams) {
        let event = eventParams.event
        let topic = payload.topic
        guard let session = sessionStore.getSession(forTopic: topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
            return
        }
        if session.selfIsController {
            guard session.hasPermission(forEvents: event.type) else {
                relayer.respondError(for: payload, reason: .unauthorizedEventType(event.type))
                return
            }
        }
        let eventPublicRepresentation = Session.Event(type: event.type, data: event.data, chainId: eventParams.chainId)
        relayer.respondSuccess(for: payload)
        onEventReceived?(topic, eventPublicRepresentation)
    }
    
    private func validateEvents(session: WCSession, params: SessionType.EventParams) throws {
        if session.selfIsController {
            return
        } else {
            guard session.events.contains(params.event.type) else {
                throw WalletConnectError.invalidEventType
            }
        }
    }
    
    private func setupExpirationHandling() {
        sessionStore.onSessionExpiration = { [weak self] session in
            self?.kms.deletePrivateKey(for: session.selfParticipant.publicKey)
            self?.kms.deleteAgreementSecret(for: session.topic)
        }
    }
    
    private func restoreSubscriptions() {
        relayer.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sessionStore.getAll().map{$0.topic}
                topics.forEach{self.wcSubscriber.setSubscription(topic: $0)}
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
            wcSubscriber.removeSubscription(topic: topic)
            sessionStore.delete(topic: topic)
            kms.deleteAgreementSecret(for: topic)
            kms.deletePrivateKey(for: session.publicKey!)
        }
    }
}
