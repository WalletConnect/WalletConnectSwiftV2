import Foundation
import Combine

final class SessionEngine {
    enum Errors: Error {
        case sessionNotFound(topic: String)
    }

    var onSessionRequest: ((Request) -> Void)?
    var onSessionResponse: ((Response) -> Void)?
    var onSessionRejected: ((String, SessionType.Reason) -> Void)?
    var onSessionDelete: ((String, SessionType.Reason) -> Void)?
    var onEventReceived: ((String, Session.Event, Blockchain?) -> Void)?

    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        sessionStore: WCSessionStorage,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.sessionStore = sessionStore
        self.logger = logger

        setupConnectionSubscriptions()
        setupRequestSubscriptions()
        setupResponseSubscriptions()
        setupExpirationSubscriptions()
    }

    func hasSession(for topic: String) -> Bool {
        return sessionStore.hasSession(forTopic: topic)
    }

    func getSessions() -> [Session] {
        sessionStore.getAll().map {$0.publicRepresentation()}
    }

    func request(_ request: Request) async throws {
        logger.debug("will request on session topic: \(request.topic)")
        guard let session = sessionStore.getSession(forTopic: request.topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(request.topic)")
            return // TODO: Marked to review on developer facing error cases
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            throw WalletConnectError.invalidPermissions
        }
        let chainRequest = SessionType.RequestParams.Request(method: request.method, params: request.params)
        let sessionRequestParams = SessionType.RequestParams(request: chainRequest, chainId: request.chainId)
        let protocolMethod = SessionRequestProtocolMethod()
        let rpcRequest = RPCRequest(method: protocolMethod.method, params: sessionRequestParams)
        try await networkingInteractor.request(rpcRequest, topic: request.topic, protocolMethod: SessionRequestProtocolMethod())
    }

    func respondSessionRequest(topic: String, requestId: RPCID, result: RPCResult) async throws {
        guard sessionStore.hasSession(forTopic: topic) else {
            throw Errors.sessionNotFound(topic: topic)
        }
      
      var response = RPCResponse(id: requestId, result: result)
      
      if case .error(let value) = result {
        response = RPCResponse(id: requestId, error: value);
      }
        try await networkingInteractor.respond(topic: topic, response: response, protocolMethod: SessionRequestProtocolMethod())
    }

    func emit(topic: String, event: SessionType.EventParams.Event, chainId: Blockchain) async throws {
        let protocolMethod = SessionEventProtocolMethod()
        guard let session = sessionStore.getSession(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        guard session.hasPermission(forEvent: event.name, onChain: chainId) else {
            throw WalletConnectError.invalidEvent
        }
        let rpcRequest = RPCRequest(method: protocolMethod.method, params: SessionType.EventParams(event: event, chainId: chainId))
        try await networkingInteractor.request(rpcRequest, topic: topic, protocolMethod: protocolMethod)
    }
}

// MARK: - Privates

private extension SessionEngine {

    func setupConnectionSubscriptions() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                sessionStore.getAll()
                    .forEach { session in
                        Task(priority: .high) { try await networkingInteractor.subscribe(topic: session.topic) }
                    }
            }
            .store(in: &publishers)
    }

    func setupRequestSubscriptions() {
        networkingInteractor.requestSubscription(on: SessionDeleteProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.DeleteParams>) in
                onSessionDelete(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SessionRequestProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.RequestParams>) in
                onSessionRequest(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SessionPingProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.PingParams>) in
                onSessionPing(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SessionEventProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.EventParams>) in
                onSessionEvent(payload: payload)
            }.store(in: &publishers)
    }

    func setupResponseSubscriptions() {
        networkingInteractor.responseSubscription(on: SessionRequestProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.RequestParams, RPCResult>) in
                onSessionResponse?(Response(
                    id: payload.id,
                    topic: payload.topic,
                    chainId: payload.request.chainId.absoluteString,
                    result: payload.response
                ))
            }
            .store(in: &publishers)
    }

    func setupExpirationSubscriptions() {
        sessionStore.onSessionExpiration = { [weak self] session in
            self?.kms.deletePrivateKey(for: session.selfParticipant.publicKey)
            self?.kms.deleteAgreementSecret(for: session.topic)
        }
    }

    func respondError(payload: SubscriptionPayload, reason: SignReasonCode, protocolMethod: ProtocolMethod) {
        Task(priority: .high) {
            do {
                try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    func onSessionDelete(payload: RequestSubscriptionPayload<SessionType.DeleteParams>) {
        let protocolMethod = SessionDeleteProtocolMethod()
        let topic = payload.topic
        guard sessionStore.hasSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, protocolMethod: protocolMethod)
        }
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod)
        }
        onSessionDelete?(topic, payload.request)
    }

    func onSessionRequest(payload: RequestSubscriptionPayload<SessionType.RequestParams>) {
        let protocolMethod = SessionRequestProtocolMethod()
        let topic = payload.topic
        let request = Request(
            id: payload.id,
            topic: payload.topic,
            method: payload.request.request.method,
            params: payload.request.request.params,
            chainId: payload.request.chainId)

        guard let session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, protocolMethod: protocolMethod)
        }
        guard session.hasNamespace(for: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedChain, protocolMethod: protocolMethod)
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedMethod(request.method), protocolMethod: protocolMethod)
        }
        onSessionRequest?(request)
    }

    func onSessionPing(payload: SubscriptionPayload) {
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: SessionPingProtocolMethod())
        }
    }

    func onSessionEvent(payload: RequestSubscriptionPayload<SessionType.EventParams>) {
        let protocolMethod = SessionEventProtocolMethod()
        let event = payload.request.event
        let topic = payload.topic
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, protocolMethod: protocolMethod)
        }
        guard session.peerIsController, session.hasPermission(forEvent: event.name, onChain: payload.request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedEvent(event.name), protocolMethod: protocolMethod)
        }
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod)
        }
        onEventReceived?(topic, event.publicRepresentation(), payload.request.chainId)
    }
}
