import Foundation
import Combine

final class SessionEngine {
    enum Errors: Error {
        case sessionRequestExpired
    }

    var onSessionsUpdate: (([Session]) -> Void)?
    var onSessionResponse: ((Response) -> Void)?
    var onSessionDelete: ((String, SessionType.Reason) -> Void)?
    var onEventReceived: ((String, Session.Event, Blockchain?) -> Void)?

    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        return sessionRequestsProvider.sessionRequestPublisher
    }


    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting
    private let historyService: HistoryServiceProtocol
    private let verifyContextStore: CodableStore<VerifyContext>
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let sessionRequestsProvider: SessionRequestsProvider
    private let invalidRequestsSanitiser: InvalidRequestsSanitiser

    init(
        networkingInteractor: NetworkInteracting,
        historyService: HistoryServiceProtocol,
        verifyContextStore: CodableStore<VerifyContext>,
        kms: KeyManagementServiceProtocol,
        sessionStore: WCSessionStorage,
        logger: ConsoleLogging,
        sessionRequestsProvider: SessionRequestsProvider,
        invalidRequestsSanitiser: InvalidRequestsSanitiser
    ) {
        self.networkingInteractor = networkingInteractor
        self.historyService = historyService
        self.verifyContextStore = verifyContextStore
        self.kms = kms
        self.sessionStore = sessionStore
        self.logger = logger
        self.sessionRequestsProvider = sessionRequestsProvider
        self.invalidRequestsSanitiser = invalidRequestsSanitiser

        setupConnectionSubscriptions()
        setupRequestSubscriptions()
        setupResponseSubscriptions()
        setupUpdateSubscriptions()
        setupExpirationSubscriptions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.sessionRequestsProvider.emitRequestIfPending()
        }

        removeInvalidSessionRequests()
    }

    private func removeInvalidSessionRequests() {
        let sessionTopics = Set(sessionStore.getAll().map(\.topic))
        invalidRequestsSanitiser.removeInvalidSessionRequests(validSessionTopics: sessionTopics)
    }

    func hasSession(for topic: String) -> Bool {
        return sessionStore.hasSession(forTopic: topic)
    }
    
    func getSessions() -> [Session] {
        sessionStore.getAll().map { $0.publicRepresentation() }
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
                let topics = sessionStore.getAll().map{$0.topic}
                Task(priority: .high) {
                    try await networkingInteractor.batchSubscribe(topics: topics)
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
                Task(priority: .high) {
                    onSessionRequest(payload: payload)
                }
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
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.RequestParams, AnyCodable>) in
                onSessionResponse?(Response(
                    id: payload.id,
                    topic: payload.topic,
                    chainId: payload.request.chainId.absoluteString,
                    result: .response(payload.response)
                ))
            }
            .store(in: &publishers)

        networkingInteractor.responseErrorSubscription(on: SessionRequestProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<SessionType.RequestParams>) in
                onSessionResponse?(Response(
                    id: payload.id,
                    topic: payload.topic,
                    chainId: payload.request.chainId.absoluteString,
                    result: .error(payload.error)
                ))
            }
            .store(in: &publishers)
    }

    func setupExpirationSubscriptions() {
        sessionStore.onSessionExpiration = { [weak self] session in
            self?.historyService.removePendingRequest(topic: session.topic)
            self?.kms.deletePrivateKey(for: session.selfParticipant.publicKey)
            self?.kms.deleteAgreementSecret(for: session.topic)
        }
    }

    func setupUpdateSubscriptions() {
        sessionStore.onSessionsUpdate = { [weak self] in
            guard let self else { return }
            self.onSessionsUpdate?(self.getSessions())
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
        logger.debug("Received session request")
        let protocolMethod = SessionRequestProtocolMethod()
        let topic = payload.topic
        let request = Request(
            id: payload.id,
            topic: payload.topic,
            method: payload.request.request.method,
            params: payload.request.request.params,
            chainId: payload.request.chainId,
            expiryTimestamp: payload.request.request.expiryTimestamp
        )
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, protocolMethod: protocolMethod)
        }
        guard session.hasNamespace(for: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedChain, protocolMethod: protocolMethod)
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedMethod(request.method), protocolMethod: protocolMethod)
        }
        guard !request.isExpired() else {
            return respondError(payload: payload, reason: .sessionRequestExpired, protocolMethod: protocolMethod)
        }
        let verifyContext = session.verifyContext ?? VerifyContext(origin: nil, validation: .unknown)
        verifyContextStore.set(verifyContext, forKey: request.id.string)
        sessionRequestsProvider.emitRequestIfPending()
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

extension SessionEngine.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .sessionRequestExpired:    return "Session request expired"
        }
    }
}
