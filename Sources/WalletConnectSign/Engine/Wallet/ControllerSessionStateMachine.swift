import Foundation
import Combine

final class ControllerSessionStateMachine {
    var onNamespacesUpdate: ((String, [String: SessionNamespace]) -> Void)?

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

    func update(topic: String, namespaces: [String: SessionNamespace]) async throws {
        let session = try getSession(for: topic)
        let protocolMethod = SessionUpdateProtocolMethod()
        try validateController(session)
        try Namespace.validate(namespaces)
        logger.debug("Controller will update methods")
        sessionStore.setSession(session)
        let request = RPCRequest(method: protocolMethod.method, params: SessionType.UpdateParams(namespaces: namespaces))
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
    }

    // MARK: - Handle Response
    private func setupSubscriptions() {
        networkingInteractor.responseSubscription(on: SessionUpdateProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.UpdateParams, RPCResult>) in
                handleUpdateResponse(payload: payload)
            }
            .store(in: &publishers)
    }

    private func handleUpdateResponse(payload: ResponseSubscriptionPayload<SessionType.UpdateParams, RPCResult>) {
        guard var session = sessionStore.getSession(forTopic: payload.topic) else { return }
        switch payload.response {
        case .response:
            do {
                try session.updateNamespaces(payload.request.namespaces, timestamp: payload.id.timestamp)

                if sessionStore.setSessionIfNewer(session) {
                    onNamespacesUpdate?(session.topic, session.namespaces)
                }
            } catch {
                logger.error("Update namespaces error: \(error.localizedDescription)")
            }
        case .error:
            logger.error("Peer failed to update session")
        }
    }

    // MARK: - Private
    private func getSession(for topic: String) throws -> WCSession {
        if let session = sessionStore.getSession(forTopic: topic) {
            return session
        } else {
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }
    }

    private func validateController(_ session: WCSession) throws {
        guard session.selfIsController else {
            throw WalletConnectError.unauthorizedNonControllerCall
        }
    }
}
