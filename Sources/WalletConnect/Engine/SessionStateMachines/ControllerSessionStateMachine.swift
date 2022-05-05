
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import Combine

final class ControllerSessionStateMachine: SessionStateMachineValidating {
    var onAccountsUpdate: ((String, Set<Account>)->())?
    var onNamespacesUpdate: ((String, Set<Namespace>)->())?
    var onExpiryUpdate: ((String, Date)->())?

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
    
    func updateAccounts(topic: String, accounts: Set<Account>) throws {
        var session = try getSession(for: topic)
        try validateControlledAcknowledged(session)
        session.updateAccounts(accounts)
        sessionStore.setSession(session)
        networkingInteractor.request(.wcSessionUpdateAccounts(SessionType.UpdateAccountsParams(accounts: accounts)), onTopic: topic)
    }
    
    func updateNamespaces(topic: String, namespaces: Set<Namespace>) throws {
        var session = try getSession(for: topic)
        try validateControlledAcknowledged(session)
        try validateNamespaces(namespaces)
        logger.debug("Controller will update methods")
        session.updateNamespaces(namespaces)
        sessionStore.setSession(session)
        networkingInteractor.request(.wcSessionUpdateNamespaces(SessionType.UpdateNamespaceParams(namespaces: namespaces)), onTopic: topic)
    }
    
   func updateExpiry(topic: String, by ttl: Int64) throws {
       var session = try getSession(for: topic)
       try validateControlledAcknowledged(session)
       try session.updateExpiry(by: ttl)
       let newExpiry = Int64(session.expiryDate.timeIntervalSince1970 )
       sessionStore.setSession(session)
       networkingInteractor.request(.wcSessionUpdateExpiry(SessionType.UpdateExpiryParams(expiry: newExpiry)), onTopic: topic)
   }
    
    // MARK: - Handle Response
    
    private func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionUpdateAccounts:
            handleUpdateAccountsResponse(topic: response.topic, result: response.result)
        case .sessionUpdateNamespaces:
            handleUpdateNamespacesResponse(topic: response.topic, result: response.result)
        case .sessionUpdateExpiry:
            handleUpdateExpiryResponse(topic: response.topic, result: response.result)
        default:
            break
        }
    }
    
    private func handleUpdateAccountsResponse(topic: String, result: JsonRpcResult) {
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return
        }
        let accounts = session.accounts
        switch result {
        case .response:
            onAccountsUpdate?(topic, accounts)
        case .error:
            logger.error("Peer failed to update state.")
        }
    }
    
    private func handleUpdateNamespacesResponse(topic: String, result: JsonRpcResult) {
        guard let session = sessionStore.getSession(forTopic: topic) else {
            return
        }
        switch result {
        case .response:
            //TODO - state sync
            onNamespacesUpdate?(session.topic, session.namespaces)
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
            onExpiryUpdate?(session.topic, session.expiryDate)
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
