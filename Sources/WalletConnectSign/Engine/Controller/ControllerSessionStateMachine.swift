import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class ControllerSessionStateMachine {

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
        networkingInteractor.responsePublisher.sink { [unowned self] response in
            handleResponse(response)
        }.store(in: &publishers)
    }

    func update(topic: String, namespaces: [String: SessionNamespace]) async throws {
        var session = try getSession(for: topic)
        try validateControlledAcknowledged(session)
        try Namespace.validate(namespaces)
        logger.debug("Controller will update methods")
        sessionStore.setSession(session)
        try await networkingInteractor.request(.wcSessionUpdate(SessionType.UpdateParams(namespaces: namespaces)), onTopic: topic)
    }

   func extend(topic: String, by ttl: Int64) async throws {
       var session = try getSession(for: topic)
       try validateControlledAcknowledged(session)
       try session.updateExpiry(by: ttl)
       let newExpiry = Int64(session.expiryDate.timeIntervalSince1970 )
       sessionStore.setSession(session)
       try await networkingInteractor.request(.wcSessionExtend(SessionType.UpdateExpiryParams(expiry: newExpiry)), onTopic: topic)
   }

    // MARK: - Handle Response

    private func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionUpdate(let payload):
            handleUpdateResponse(response: response, payload: payload)
        case .sessionExtend(let payload):
            handleUpdateExpiryResponse(response: response, payload: payload)
        default:
            break
        }
    }

    private func handleUpdateResponse(response: WCResponse, payload: SessionType.UpdateParams) {
        guard var session = sessionStore.getSession(forTopic: response.topic) else { return }
        switch response.result {
        case .response:
            do {
                try session.updateNamespaces(payload.namespaces, timestamp: response.timestamp)

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

    private func handleUpdateExpiryResponse(response: WCResponse, payload: SessionType.UpdateExpiryParams) {
        guard var session = sessionStore.getSession(forTopic: response.topic) else { return }
        switch response.result {
        case .response:
            do {
                try session.updateExpiry(to: payload.expiry)
                sessionStore.setSession(session)
                onExtend?(session.topic, session.expiryDate)
            } catch {
                logger.error("Update expiry error: \(error.localizedDescription)")
            }
        case .error:
            logger.error("Peer failed to extend session")
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

    private func validateControlledAcknowledged(_ session: WCSession) throws {
        guard session.acknowledged else {
            throw WalletConnectError.sessionNotAcknowledged(session.topic)
        }
        guard session.selfIsController else {
            throw WalletConnectError.unauthorizedNonControllerCall
        }
    }
}
