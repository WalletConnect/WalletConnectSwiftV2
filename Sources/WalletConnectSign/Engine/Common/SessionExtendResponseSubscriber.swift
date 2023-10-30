import Foundation
import Combine

final class SessionExtendResponseSubscriber {
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

    // MARK: - Handle Response
    private func setupSubscriptions() {
        networkingInteractor.responseSubscription(on: SessionExtendProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.UpdateExpiryParams, RPCResult>) in
                handleUpdateExpiryResponse(payload: payload)
            }
            .store(in: &publishers)
    }

    private func handleUpdateExpiryResponse(payload: ResponseSubscriptionPayload<SessionType.UpdateExpiryParams, RPCResult>) {
        guard var session = sessionStore.getSession(forTopic: payload.topic) else { return }
        switch payload.response {
        case .response:
            do {
                try session.updateExpiry(to: payload.request.expiry)
                sessionStore.setSession(session)
                onExtend?(session.topic, session.expiryDate)
            } catch {
                logger.error("Update expiry error: \(error.localizedDescription)")
            }
        case .error:
            logger.error("Peer failed to extend session")
        }
    }
}
