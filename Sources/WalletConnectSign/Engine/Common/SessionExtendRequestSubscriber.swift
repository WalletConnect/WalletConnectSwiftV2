import Foundation
import Combine

final class SessionExtendRequestSubscriber {
    var onExtend: ((String, Date) -> Void)?
    
    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    
    init(
        networkingInteractor: NetworkInteracting,
        sessionStore: WCSessionStorage,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.sessionStore = sessionStore
        self.logger = logger
        
        setupSubscriptions()
    }
}

// MARK: - Private functions
extension SessionExtendRequestSubscriber {
    private func setupSubscriptions() {
        networkingInteractor.requestSubscription(on: SessionExtendProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.UpdateExpiryParams>) in
                onSessionUpdateExpiry(payload: payload, updateExpiryParams: payload.request)
            }.store(in: &publishers)
    }

    private func onSessionUpdateExpiry(payload: SubscriptionPayload, updateExpiryParams: SessionType.UpdateExpiryParams) {
        let protocolMethod = SessionExtendProtocolMethod()
        let topic = payload.topic
        guard var session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, protocolMethod: protocolMethod)
        }
        guard session.peerIsController else {
            return respondError(payload: payload, reason: .unauthorizedExtendRequest, protocolMethod: protocolMethod)
        }
        do {
            try session.updateExpiry(to: updateExpiryParams.expiry)
        } catch {
            return respondError(payload: payload, reason: .invalidExtendRequest, protocolMethod: protocolMethod)
        }
        sessionStore.setSession(session)

        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod)
        }

        onExtend?(session.topic, session.expiryDate)
    }
    
    private func respondError(payload: SubscriptionPayload, reason: SignReasonCode, protocolMethod: ProtocolMethod) {
        Task(priority: .high) {
            do {
                try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }
}
