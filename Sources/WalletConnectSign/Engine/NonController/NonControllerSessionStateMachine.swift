import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class NonControllerSessionStateMachine {
    enum Errors: Error {
        case respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode)
    }

    var onNamespacesUpdate: ((String, [String: SessionNamespace]) -> Void)?
    var onExtend: ((String, Date) -> Void)?

    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         sessionStore: WCSessionStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.sessionStore = sessionStore
        self.logger = logger
        setUpWCRequestHandling()
    }

    private func setUpWCRequestHandling() {
        networkingInteractor.wcRequestPublisher
            .sink { [unowned self] subscriptionPayload in
                do {
                    switch subscriptionPayload.wcRequest.params {
                    case .sessionUpdate(let updateParams):
                        try onSessionUpdateNamespacesRequest(payload: subscriptionPayload, updateParams: updateParams)
                    case .sessionExtend(let updateExpiryParams):
                        try onSessionUpdateExpiry(subscriptionPayload, updateExpiryParams: updateExpiryParams)
                    default: return
                    }
                } catch Errors.respondError(let payload, let reason) {
                    respondError(payload: payload, reason: reason)
                } catch {
                    logger.error("Unexpected Error: \(error.localizedDescription)")
                }
            }.store(in: &publishers)
    }

    private func respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode) {
        Task {
            do {
                try await networkingInteractor.respondError(payload: payload, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    // TODO: Update stored session namespaces
    private func onSessionUpdateNamespacesRequest(payload: WCRequestSubscriptionPayload, updateParams: SessionType.UpdateParams) throws {
        do {
            try Namespace.validate(updateParams.namespaces)
        } catch {
            throw Errors.respondError(payload: payload, reason: .invalidUpdateNamespaceRequest)
        }
        guard var session = sessionStore.getSession(forTopic: payload.topic) else {
            throw Errors.respondError(payload: payload, reason: .noContextWithTopic(context: .session, topic: payload.topic))
        }
        guard session.peerIsController else {
            throw Errors.respondError(payload: payload, reason: .unauthorizedUpdateNamespacesRequest)
        }
        session.updateNamespaces(updateParams.namespaces)
        sessionStore.setSession(session)
        networkingInteractor.respondSuccess(for: payload)
        onNamespacesUpdate?(session.topic, updateParams.namespaces)
    }

    private func onSessionUpdateExpiry(_ payload: WCRequestSubscriptionPayload, updateExpiryParams: SessionType.UpdateExpiryParams) throws {
        let topic = payload.topic
        guard var session = sessionStore.getSession(forTopic: topic) else {
            throw Errors.respondError(payload: payload, reason: .noContextWithTopic(context: .session, topic: topic))
        }
        guard session.peerIsController else {
            throw Errors.respondError(payload: payload, reason: .unauthorizedUpdateExpiryRequest)
        }
        do {
            try session.updateExpiry(to: updateExpiryParams.expiry)
        } catch {
            throw Errors.respondError(payload: payload, reason: .invalidUpdateExpiryRequest)
        }
        sessionStore.setSession(session)
        networkingInteractor.respondSuccess(for: payload)
        onExtend?(session.topic, session.expiryDate)
    }
}
