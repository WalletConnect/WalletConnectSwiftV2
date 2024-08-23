import Foundation
import Combine

class LinkSessionRequestSubscriber {

    private let sessionRequestsProvider: SessionRequestsProvider
    private let sessionStore: WCSessionStorage
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let envelopesDispatcher: LinkEnvelopesDispatcher
    private let eventsClient: EventsClientProtocol

    init(
        sessionRequestsProvider: SessionRequestsProvider,
        sessionStore: WCSessionStorage,
        logger: ConsoleLogging,
        envelopesDispatcher: LinkEnvelopesDispatcher,
        eventsClient: EventsClientProtocol
    ) {
        self.sessionRequestsProvider = sessionRequestsProvider
        self.sessionStore = sessionStore
        self.logger = logger
        self.envelopesDispatcher = envelopesDispatcher
        self.eventsClient = eventsClient
        setupRequestSubscription()
    }

    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        return sessionRequestsProvider.sessionRequestPublisher
    }

    private func setupRequestSubscription() {
        envelopesDispatcher.requestSubscription(on: SessionRequestProtocolMethod().method)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.RequestParams>) in
                Task(priority: .low) { eventsClient.saveMessageEvent(.sessionRequestLinkModeReceived(payload.id)) }

                Task(priority: .high) {
                    onSessionRequest(payload: payload)
                }
            }.store(in: &publishers)
    }

    private func upgradeSessionToLinkModeIfNeeded( _ session: inout WCSession) {
        guard session.transportType != .linkMode else {return}
        session.transportType = .linkMode
        sessionStore.setSession(session)
        logger.debug("session with topic: \(session.topic) upgraded to link mode")
    }

    func onSessionRequest(payload: RequestSubscriptionPayload<SessionType.RequestParams>) {
        logger.debug("Received session request")
        let topic = payload.topic
        let request = Request(
            id: payload.id,
            topic: payload.topic,
            method: payload.request.request.method,
            params: payload.request.request.params,
            chainId: payload.request.chainId,
            expiryTimestamp: payload.request.request.expiryTimestamp
        )
        guard var session = sessionStore.getSession(forTopic: topic) else {
            logger.debug("Session for topic not found")
            return
        }
        upgradeSessionToLinkModeIfNeeded(&session)
        guard let peerUniversalLink = session.peerParticipant.metadata.redirect?.universal else {
            logger.debug("Peer universal link not found")
            return
        }
        guard session.hasNamespace(for: request.chainId) else {
            logger.debug("Session does not have namespace for chainId")
            return respondError(payload: payload, reason: .unauthorizedChain, peerUniversalLink: peerUniversalLink)
        }
        guard session.hasPermission(forMethod: request.method, onChain: request.chainId) else {
            logger.debug("Session does not have permission for method")
            return respondError(payload: payload, reason: .unauthorizedMethod(request.method), peerUniversalLink: peerUniversalLink)
        }
        guard !request.isExpired() else {
            logger.debug("Request is expired")
            return respondError(payload: payload, reason: .sessionRequestExpired, peerUniversalLink: peerUniversalLink)
        }

        logger.debug("will emit request")
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
