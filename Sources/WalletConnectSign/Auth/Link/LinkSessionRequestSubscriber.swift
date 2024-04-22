import Foundation
import Combine

class LinkSessionRequestSubscriber {

    private let sessionRequestsProvider: SessionRequestsProvider
    private let sessionStore: WCSessionStorage
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let envelopesDispatcher: LinkEnvelopesDispatcher

    init(
        sessionRequestsProvider: SessionRequestsProvider,
        sessionStore: WCSessionStorage,
        logger: ConsoleLogging,
        envelopesDispatcher: LinkEnvelopesDispatcher
    ) {
        self.sessionRequestsProvider = sessionRequestsProvider
        self.sessionStore = sessionStore
        self.logger = logger
        self.envelopesDispatcher = envelopesDispatcher
    }

    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        return sessionRequestsProvider.sessionRequestPublisher
    }

    func setupRequestSubscriptions() {
        envelopesDispatcher.requestSubscription(on: SessionRequestProtocolMethod().method)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.RequestParams>) in
                Task(priority: .high) {
                    onSessionRequest(payload: payload)
                }
            }.store(in: &publishers)
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
            logger.debug("Session for topic not found")
            return
        }
        guard let peerUniversalLink = session.peerParticipant.metadata.redirect?.universal else {
            logger.debug("Peer universal link not found")
            return
        }
        guard session.hasNamespace(for: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedChain, peerUniversalLink: peerUniversalLink)
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            return respondError(payload: payload, reason: .unauthorizedMethod(request.method), peerUniversalLink: peerUniversalLink)
        }
        guard !request.isExpired() else {
            return respondError(payload: payload, reason: .sessionRequestExpired, peerUniversalLink: peerUniversalLink)
        }

        sessionRequestsProvider.emitRequestIfPending()
    }

    func respondError(payload: SubscriptionPayload, reason: SignReasonCode, peerUniversalLink: String) {
        Task(priority: .high) {
            do {

                try await envelopesDispatcher.respondError(topic: payload.topic, requestId: payload.id, peerUniversalLink: peerUniversalLink, reason: reason, envelopeType: .type0)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }
}
