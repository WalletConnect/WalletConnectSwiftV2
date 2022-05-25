
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class ControllerSessionStateMachine {
    var onNamespacesUpdate: ((String, [String: SessionNamespace])->())?
    var onExtend: ((String, Date)->())?

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
        session.updateNamespaces(namespaces)
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
        case .sessionUpdate:
            handleUpdateResponse(topic: response.topic, result: response.result)
        case .sessionExtend:
            handleUpdateExpiryResponse(topic: response.topic, result: response.result)
        default:
            break
        }
    }
    
    // TODO: Re-enable callback
    private func handleUpdateResponse(topic: String, result: JsonRpcResult) {
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return
        }
        switch result {
        case .response:
            //TODO - state sync
//            onNamespacesUpdate?(session.topic, session.namespaces)
            break
        case .error:
            //TODO - state sync
            logger.error("Peer failed to update methods.")
        }
    }
    
    private func handleUpdateExpiryResponse(topic: String, result: JsonRpcResult) {
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return
        }
        switch result {
        case .response:
            //TODO - state sync
            onExtend?(session.topic, session.expiryDate)
        case .error:
            //TODO - state sync
            logger.error("Peer failed to update events.")
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
