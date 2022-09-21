import Foundation
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking
import Combine

final class NonControllerSessionStateMachine {

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
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        networkingInteractor.requestSubscription(on: SignProtocolMethod.sessionUpdate)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.UpdateParams>) in
                onSessionUpdateNamespacesRequest(payload: payload, updateParams: payload.request)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SignProtocolMethod.sessionExtend)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.UpdateExpiryParams>) in
                onSessionUpdateExpiry(payload: payload, updateExpiryParams: payload.request)
            }.store(in: &publishers)
    }

    private func respondError(payload: SubscriptionPayload, reason: ReasonCode, tag: Int) {
        Task(priority: .high) {
            do {
                try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, tag: tag, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    // TODO: Update stored session namespaces
    private func onSessionUpdateNamespacesRequest(payload: SubscriptionPayload, updateParams: SessionType.UpdateParams) {
        do {
            try Namespace.validate(updateParams.namespaces)
        } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, tag: SignProtocolMethod.sessionUpdate.responseTag)
        }
        guard var session = sessionStore.getSession(forTopic: payload.topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, tag: SignProtocolMethod.sessionUpdate.responseTag)
        }
        guard session.peerIsController else {
            return respondError(payload: payload, reason: .unauthorizedUpdateRequest, tag: SignProtocolMethod.sessionUpdate.responseTag)
        }
        do {
            try session.updateNamespaces(updateParams.namespaces, timestamp: payload.id.timestamp)
        } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, tag: SignProtocolMethod.sessionUpdate.responseTag)
        }
        sessionStore.setSession(session)

        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: SignProtocolMethod.sessionUpdate.responseTag)
        }

        onNamespacesUpdate?(session.topic, updateParams.namespaces)
    }

    private func onSessionUpdateExpiry(payload: SubscriptionPayload, updateExpiryParams: SessionType.UpdateExpiryParams) {
        let topic = payload.topic
        guard var session = sessionStore.getSession(forTopic: topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, tag: SignProtocolMethod.sessionExtend.responseTag)
        }
        guard session.peerIsController else {
            return respondError(payload: payload, reason: .unauthorizedExtendRequest, tag: SignProtocolMethod.sessionExtend.responseTag)
        }
        do {
            try session.updateExpiry(to: updateExpiryParams.expiry)
        } catch {
            return respondError(payload: payload, reason: .invalidExtendRequest, tag: SignProtocolMethod.sessionExtend.responseTag)
        }
        sessionStore.setSession(session)

        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: SignProtocolMethod.sessionExtend.responseTag)
        }

        onExtend?(session.topic, session.expiryDate)
    }
}
