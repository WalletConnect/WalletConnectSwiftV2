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

        setupNetworkingSubscriptions()
        setupExpirationSubscriptions()
    }

    func hasSession(for topic: String) -> Bool {
        return sessionStore.hasSession(forTopic: topic)
    }

    func getSessions() -> [Session] {
        sessionStore.getAll().map {$0.publicRepresentation()}
    }

    func ping(topic: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard sessionStore.hasSession(forTopic: topic) else {
            logger.debug("Could not find session to ping for topic \(topic)")
            return
        }
// TODO: Ping disabled
//        networkingInteractor.requestPeerResponse(.wcSessionPing, onTopic: topic) { [unowned self] result in
//            switch result {
//            case .success:
//                logger.debug("Did receive ping response")
//                completion(.success(()))
//            case .failure(let error):
//                logger.debug("error: \(error)")
//            }
//        }
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

        let payload = WCRequest.sessionRequest(sessionRequestParams)
        let rpcRequest = RPCRequest(method: WCRequest.Method.sessionRequest.method, params: payload)
        try await networkingInteractor.request(rpcRequest, topic: request.topic, tag: WCRequest.Method.sessionRequest.requestTag)
    }

    func respondSessionRequest(topic: String, response: JsonRpcResult) async throws {
        guard sessionStore.hasSession(forTopic: topic) else {
            throw Errors.sessionNotFound(topic: topic)
        }
        // TODO: ???
//        try await networkingInteractor.respond(topic: topic, response: response, tag: 1109) // FIXME: Hardcoded tag
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
        let rpcRequest = RPCRequest(method: WCRequest.Method.sessionEvent.method, params: params)
        try await networkingInteractor.request(rpcRequest, topic: topic, tag: WCRequest.Method.sessionEvent.requestTag)
    }
}

// MARK: - Privates

private extension SessionEngine {

    func setupNetworkingSubscriptions() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                sessionStore.getAll()
                    .forEach { session in
                        Task { try await networkingInteractor.subscribe(topic: session.topic) }
                    }
            }
            .store(in: &publishers)

        networkingInteractor.requestSubscription(on: nil)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<WCRequest>) in
                switch payload.request {
                case .sessionDelete(let params):
                    onSessionDelete(payload, params: params)
                case .sessionRequest(let params):
                    onSessionRequest(payload, params: params)
                case .sessionPing:
                    onSessionPing(payload)
                case .sessionEvent(let params):
                    onSessionEvent(payload, params: params)
                default: return
                }
            }
            .store(in: &publishers)

        networkingInteractor.responseSubscription(on: nil)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<WCRequest, JsonRpcResult>) in
                switch payload.request {
                case .sessionRequest(let params):
                    // TODO: ??? Chain ID from request is ok?
                    // Need to check absolute string
                    let response = Response(topic: payload.topic, chainId: params.chainId.absoluteString, result: payload.response)
                    onSessionResponse?(response)
                default:
                    break
                }
            }
            .store(in: &publishers)
    }

    func respondError(payload: SubscriptionPayload, reason: ReasonCode, tag: Int) {
        Task {
            do {
                try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, tag: tag, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    func onSessionDelete(_ payload: SubscriptionPayload, params: SessionType.DeleteParams) {
        let tag = WCRequest.Method.sessionDelete.responseTag
        let topic = payload.topic
        guard sessionStore.hasSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, tag: tag)
        }
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: tag)
        }
        onSessionDelete?(topic, params)
    }

    func onSessionRequest(_ payload: SubscriptionPayload, params: SessionType.RequestParams) {
        let tag = WCRequest.Method.sessionRequest.responseTag
        let topic = payload.topic
        let request = Request(
            id: payload.id,
            topic: payload.topic,
            method: WCRequest.Method.sessionRequest.method,
            params: params,
            chainId: params.chainId)

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

    func onSessionPing(_ payload: SubscriptionPayload) {
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: WCRequest.Method.sessionPing.responseTag)
        }
    }

    func onSessionEvent(_ payload: SubscriptionPayload, params: SessionType.EventParams) {
        let tag = WCRequest.Method.sessionEvent.responseTag
        let event = params.event
        let topic = payload.topic
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, tag: tag)
        }
        guard session.peerIsController, session.hasPermission(forEvent: event.name, onChain: params.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedEvent(event.name), tag: tag)
        }
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: tag)
        }
        onEventReceived?(topic, event.publicRepresentation(), params.chainId)
    }

    func setupExpirationSubscriptions() {
        sessionStore.onSessionExpiration = { [weak self] session in
            self?.kms.deletePrivateKey(for: session.selfParticipant.publicKey)
            self?.kms.deleteAgreementSecret(for: session.topic)
        }
    }
}
