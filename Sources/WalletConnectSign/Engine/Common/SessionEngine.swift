import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

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

        let rpcRequest = RPCRequest(method: SignProtocolMethod.sessionRequest.method, params: sessionRequestParams)
        try await networkingInteractor.request(rpcRequest, topic: request.topic, tag: SignProtocolMethod.sessionRequest.requestTag)
    }

    func respondSessionRequest(topic: String, requestId: RPCID, response: RPCResult) async throws {
        guard sessionStore.hasSession(forTopic: topic) else {
            throw Errors.sessionNotFound(topic: topic)
        }
        let response = RPCResponse(id: requestId, result: response)
        try await networkingInteractor.respond(topic: topic, response: response, tag: 1109) // FIXME: Hardcoded tag
    }

    func emit(topic: String, event: SessionType.EventParams.Event, chainId: Blockchain) async throws {
        guard let session = sessionStore.getSession(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        guard session.hasPermission(forEvent: event.name, onChain: chainId) else {
            throw WalletConnectError.invalidEvent
        }
        let rpcRequest = RPCRequest(method: SignProtocolMethod.sessionEvent.method, params: SessionType.EventParams(event: event, chainId: chainId))
        try await networkingInteractor.request(rpcRequest, topic: topic, tag: SignProtocolMethod.sessionEvent.requestTag)
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
        networkingInteractor.requestSubscription(on: SignProtocolMethod.sessionDelete)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.DeleteParams>) in
                onSessionDelete(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SignProtocolMethod.sessionRequest)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.RequestParams>) in
                onSessionRequest(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SignProtocolMethod.sessionPing)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.PingParams>) in
                onSessionPing(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SignProtocolMethod.sessionEvent)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.EventParams>) in
                onSessionEvent(payload: payload)
            }.store(in: &publishers)
    }

    func setupResponseSubscriptions() {
        networkingInteractor.responseSubscription(on: SignProtocolMethod.sessionRequest)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.RequestParams, RPCResult>) in
                onSessionResponse?(Response(
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

    func respondError(payload: SubscriptionPayload, reason: ReasonCode, tag: Int) {
        Task(priority: .high) {
            do {
                try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, tag: tag, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    func onSessionDelete(payload: RequestSubscriptionPayload<SessionType.DeleteParams>) {
        let tag = SignProtocolMethod.sessionDelete.responseTag
        let topic = payload.topic
        guard sessionStore.hasSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, tag: tag)
        }
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: tag)
        }
        onSessionDelete?(topic, payload.request)
    }

    func onSessionRequest(payload: RequestSubscriptionPayload<SessionType.RequestParams>) {
        let tag = SignProtocolMethod.sessionRequest.responseTag
        let topic = payload.topic
        let request = Request(
            id: payload.id,
            topic: payload.topic,
            method: payload.request.request.method,
            params: payload.request.request.params,
            chainId: payload.request.chainId)

        guard let session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, tag: tag)
        }
        guard session.hasNamespace(for: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedChain, tag: tag)
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedMethod(request.method), tag: tag)
        }
        onSessionRequest?(request)
    }

    func onSessionPing(payload: SubscriptionPayload) {
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: SignProtocolMethod.sessionPing.responseTag)
        }
    }

    func onSessionEvent(payload: RequestSubscriptionPayload<SessionType.EventParams>) {
        let tag = SignProtocolMethod.sessionEvent.responseTag
        let event = payload.request.event
        let topic = payload.topic
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, tag: tag)
        }
        guard session.peerIsController, session.hasPermission(forEvent: event.name, onChain: payload.request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedEvent(event.name), tag: tag)
        }
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: tag)
        }
        onEventReceived?(topic, event.publicRepresentation(), payload.request.chainId)
    }
}
