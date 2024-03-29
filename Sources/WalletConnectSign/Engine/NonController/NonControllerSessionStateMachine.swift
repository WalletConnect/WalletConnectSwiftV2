import Foundation
import Combine

final class NonControllerSessionStateMachine {
    var onNamespacesUpdate: ((String, [String: SessionNamespace]) -> Void)?

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
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        networkingInteractor.requestSubscription(on: SessionUpdateProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.UpdateParams>) in
                onSessionUpdateNamespacesRequest(payload: payload, updateParams: payload.request)
            }.store(in: &publishers)
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

    // TODO: Update stored session namespaces
    private func onSessionUpdateNamespacesRequest(payload: SubscriptionPayload, updateParams: SessionType.UpdateParams) {
        let protocolMethod = SessionUpdateProtocolMethod()
        do {
            try Namespace.validate(updateParams.namespaces)
        } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, protocolMethod: protocolMethod)
        }
        guard var session = sessionStore.getSession(forTopic: payload.topic) else {
            return respondError(payload: payload, reason: .noSessionForTopic, protocolMethod: protocolMethod)
        }
        guard session.peerIsController else {
            return respondError(payload: payload, reason: .unauthorizedUpdateRequest, protocolMethod: protocolMethod)
        }
        do {
            try session.updateNamespaces(updateParams.namespaces, timestamp: payload.id.timestamp)
        } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, protocolMethod: protocolMethod)
        }
        sessionStore.setSession(session)

        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod)
        }

        onNamespacesUpdate?(session.topic, updateParams.namespaces)
    }
}
