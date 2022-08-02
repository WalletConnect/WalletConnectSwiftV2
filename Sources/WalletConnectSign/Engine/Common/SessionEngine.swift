import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

final class SessionEngine {
    enum Errors: Error {
        case respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode)
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

    func delete(topic: String) async throws {
        let reasonCode = ReasonCode.userDisconnected
        let reason = SessionType.Reason(code: reasonCode.code, message: reasonCode.message)
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        networkingInteractor.request(.wcSessionDelete(reason), onTopic: topic)
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }

    func ping(topic: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard sessionStore.hasSession(forTopic: topic) else {
            logger.debug("Could not find session to ping for topic \(topic)")
            return
        }
        networkingInteractor.requestPeerResponse(.wcSessionPing, onTopic: topic) { [unowned self] result in
            switch result {
            case .success:
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
        networkingInteractor.request(.wcSessionRequest(sessionRequestParams), onTopic: request.topic)
    }

    func respondSessionRequest(topic: String, response: JsonRpcResult) async throws {
        guard sessionStore.hasSession(forTopic: topic) else {
            throw Errors.sessionNotFound(topic: topic)
        }
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
        let params = SessionType.EventParams(event: event, chainId: chainId)
        networkingInteractor.request(.wcSessionEvent(params), onTopic: topic)
    }
}

// MARK: - Privates

private extension SessionEngine {

    func setupNetworkingSubscriptions() {
        networkingInteractor.wcRequestPublisher.sink { [unowned self] subscriptionPayload in
            do {
                switch subscriptionPayload.wcRequest.params {
                case .sessionDelete(let deleteParams):
                    try onSessionDelete(subscriptionPayload, deleteParams: deleteParams)
                case .sessionRequest(let sessionRequestParams):
                    try onSessionRequest(subscriptionPayload, payloadParams: sessionRequestParams)
                case .sessionPing:
                    onSessionPing(subscriptionPayload)
                case .sessionEvent(let eventParams):
                    try onSessionEvent(subscriptionPayload, eventParams: eventParams)
                default: return
                }
            } catch Errors.respondError(let payload, let reason) {
                respondError(payload: payload, reason: reason)
            } catch {
                logger.error("Unexpected Error: \(error.localizedDescription)")
            }
        }.store(in: &publishers)

        networkingInteractor.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sessionStore.getAll().map {$0.topic}
                topics.forEach { topic in Task { try? await networkingInteractor.subscribe(topic: topic) } }
            }.store(in: &publishers)

        networkingInteractor.responsePublisher
            .sink { [unowned self] response in
                self.handleResponse(response)
            }.store(in: &publishers)
    }

    func respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode) {
        Task {
            do {
                try await networkingInteractor.respondError(payload: payload, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    func onSessionDelete(_ payload: WCRequestSubscriptionPayload, deleteParams: SessionType.DeleteParams) throws {
        let topic = payload.topic
        guard sessionStore.hasSession(forTopic: topic) else {
            throw Errors.respondError(payload: payload, reason: .noContextWithTopic(context: .session, topic: topic))
        }
        sessionStore.delete(topic: topic)
        networkingInteractor.unsubscribe(topic: topic)
        networkingInteractor.respondSuccess(for: payload)
        onSessionDelete?(topic, deleteParams)
    }

    func onSessionRequest(_ payload: WCRequestSubscriptionPayload, payloadParams: SessionType.RequestParams) throws {
        let topic = payload.topic
        let jsonRpcRequest = JSONRPCRequest<AnyCodable>(id: payload.wcRequest.id, method: payloadParams.request.method, params: payloadParams.request.params)
        let request = Request(
            id: jsonRpcRequest.id,
            topic: topic,
            method: jsonRpcRequest.method,
            params: jsonRpcRequest.params,
            chainId: payloadParams.chainId)

        guard let session = sessionStore.getSession(forTopic: topic) else {
            throw Errors.respondError(payload: payload, reason: .noContextWithTopic(context: .session, topic: topic))
        }
        let chain = request.chainId
        guard session.hasNamespace(for: chain) else {
            throw Errors.respondError(payload: payload, reason: .unauthorizedTargetChain(chain.absoluteString))
        }
        guard session.hasPermission(forMethod: request.method, onChain: chain) else {
            throw Errors.respondError(payload: payload, reason: .unauthorizedMethod(request.method))
        }
        onSessionRequest?(request)
    }

    func onSessionPing(_ payload: WCRequestSubscriptionPayload) {
        networkingInteractor.respondSuccess(for: payload)
    }

    func onSessionEvent(_ payload: WCRequestSubscriptionPayload, eventParams: SessionType.EventParams) throws {
        let event = eventParams.event
        let topic = payload.topic
        guard let session = sessionStore.getSession(forTopic: topic) else {
            throw Errors.respondError(payload: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
        }
        guard
            session.peerIsController,
            session.hasPermission(forEvent: event.name, onChain: eventParams.chainId)
        else {
            throw Errors.respondError(payload: payload, reason: .unauthorizedEvent(event.name))
        }
        networkingInteractor.respondSuccess(for: payload)
        onEventReceived?(topic, event.publicRepresentation(), eventParams.chainId)
    }

    func setupExpirationSubscriptions() {
        sessionStore.onSessionExpiration = { [weak self] session in
            self?.kms.deletePrivateKey(for: session.selfParticipant.publicKey)
            self?.kms.deleteAgreementSecret(for: session.topic)
        }
    }

    func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionRequest:
            let response = Response(topic: response.topic, chainId: response.chainId, result: response.result)
            onSessionResponse?(response)
        default:
            break
        }
    }
}
