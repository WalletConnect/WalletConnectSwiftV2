
import Foundation
import Relayer
import WalletConnectUtils
import WalletConnectKMS
import Combine
#if os(iOS)
import UIKit
#endif

/// An Object that expose public API to provide interactions with WalletConnect SDK
///
/// WalletConnect Client is not a singleton but once you create an instance, you should not deinitialize it. Usually only one instance of a client is required in the application.
///
/// ```swift
/// let metadata = AppMetadata(name: String?, description: String?, url: String?, icons: [String]?)
/// let client = WalletConnectClient(metadata: AppMetadata, projectId: String, relayHost: String)
/// ```
///
/// - Parameters:
///     - delegate: The object that acts as the delegate of WalletConnect Client
///     - logger: An object for logging messages
public final class WalletConnectClient {
    public weak var delegate: WalletConnectClientDelegate?
    public let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let metadata: AppMetadata
    private let pairingEngine: PairingEngine
    private let pairMathodEngine: PairEngine
    private let sessionEngine: SessionEngine
    private let nonControllerSessionStateMachine: NonControllerSessionStateMachine
    private let controllerSessionStateMachine: ControllerSessionStateMachine
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let history: JsonRpcHistory

    // MARK: - Initializers

    /// Initializes and returns newly created WalletConnect Client Instance. Establishes a network connection with the relay
    ///
    /// - Parameters:
    ///   - metadata: describes your application and will define pairing appearance in a web browser.
    ///   - projectId: an optional parameter used to access the public WalletConnect infrastructure. Go to `www.walletconnect.com` for info.
    ///   - relayHost: proxy server host that your application will use to connect to Waku Network. If you register your project at `www.walletconnect.com` you can use `relay.walletconnect.com`
    ///   - keyValueStorage: by default WalletConnect SDK will store sequences in UserDefaults
    ///
    /// WalletConnect Client is not a singleton but once you create an instance, you should not deinitialize it. Usually only one instance of a client is required in the application.
    public convenience init(metadata: AppMetadata, projectId: String, relayHost: String, keyValueStorage: KeyValueStorage = UserDefaults.standard) {
        self.init(metadata: metadata, projectId: projectId, relayHost: relayHost, logger: ConsoleLogger(loggingLevel: .off), kms: KeyManagementService(serviceIdentifier:  "com.walletconnect.sdk"), keyValueStorage: keyValueStorage)
    }
    
    init(metadata: AppMetadata, projectId: String, relayHost: String, logger: ConsoleLogging, kms: KeyManagementService, keyValueStorage: KeyValueStorage) {
        self.metadata = metadata
        self.logger = logger
//        try? keychain.deleteAll() // Use for cleanup while lifecycles are not handled yet, but FIXME whenever
        self.kms = kms
        let relayer = Relayer(relayHost: relayHost, projectId: projectId, keyValueStorage: keyValueStorage, logger: logger)
        let serializer = Serializer(kms: kms)
        self.history = JsonRpcHistory(logger: logger, keyValueStore: KeyValueStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue))
        self.networkingInteractor = NetworkInteractor(networkRelayer: relayer, serializer: serializer, logger: logger, jsonRpcHistory: history)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(storage: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue))
        let sessionStore = SessionStorage(storage: SequenceStore<WCSession>(storage: keyValueStorage, identifier: StorageDomainIdentifiers.sessions.rawValue))
        let sessionToPairingTopic = KeyValueStore<String>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.sessionToPairingTopic.rawValue)
        self.pairingEngine = PairingEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore, sessionToPairingTopic: sessionToPairingTopic, metadata: metadata, logger: logger)
        self.sessionEngine = SessionEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore, sessionStore: sessionStore, sessionToPairingTopic: sessionToPairingTopic, metadata: metadata, logger: logger)
        self.nonControllerSessionStateMachine = NonControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        self.controllerSessionStateMachine = ControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        self.pairMathodEngine = PairEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore)
        setUpConnectionObserving(relayClient: relayer)
        setUpEnginesCallbacks()
    }
    
    /// Initializes and returns newly created WalletConnect Client Instance. Establishes a network connection with the relay
    ///
    /// - Parameters:
    ///   - metadata: describes your application and will define pairing appearance in a web browser.
    ///   - relayer: Relayer instance
    ///   - keyValueStorage: by default WalletConnect SDK will store sequences in UserDefaults but if for some reasons you want to provide your own storage you can inject it here.
    ///
    /// WalletConnect Client is not a singleton but once you create an instance, you should not deinitialize it. Usually only one instance of a client is required in the application.
    public convenience init(metadata: AppMetadata, relayer: Relayer, keyValueStorage: KeyValueStorage = UserDefaults.standard, kms: KeyManagementService = KeyManagementService(serviceIdentifier:  "com.walletconnect.sdk")) {
        self.init(metadata: metadata, relayer: relayer, logger: ConsoleLogger(loggingLevel: .off), kms: kms, keyValueStorage: keyValueStorage)
    }
    
    init(metadata: AppMetadata, relayer: Relayer, logger: ConsoleLogging, kms: KeyManagementService, keyValueStorage: KeyValueStorage) {
        self.metadata = metadata
        self.logger = logger
        self.kms = kms
        let serializer = Serializer(kms: kms)
        self.history = JsonRpcHistory(logger: logger, keyValueStore: KeyValueStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue))
        self.networkingInteractor = NetworkInteractor(networkRelayer: relayer, serializer: serializer, logger: logger, jsonRpcHistory: history)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(storage: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue))
        let sessionStore = SessionStorage(storage: SequenceStore<WCSession>(storage: keyValueStorage, identifier: StorageDomainIdentifiers.sessions.rawValue))
        let sessionToPairingTopic = KeyValueStore<String>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.sessionToPairingTopic.rawValue)
        self.pairingEngine = PairingEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore, sessionToPairingTopic: sessionToPairingTopic, metadata: metadata, logger: logger)
        self.sessionEngine = SessionEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore, sessionStore: sessionStore, sessionToPairingTopic: sessionToPairingTopic, metadata: metadata, logger: logger)
        self.nonControllerSessionStateMachine = NonControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        self.controllerSessionStateMachine = ControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        self.pairMathodEngine = PairEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore)
        setUpConnectionObserving(relayClient: relayer)
        setUpEnginesCallbacks()
    }
    
    func setUpConnectionObserving(relayClient: Relayer) {
        relayClient.socketConnectionStatusPublisher.sink { [weak self] status in
            switch status {
            case .connected:
                self?.delegate?.didConnect()
            case .disconnected:
                self?.delegate?.didDisconnect()
            }
        }.store(in: &publishers)
    }

    // MARK: - Public interface

    /// For the Proposer to propose a session to a responder.
    /// Function will create pending pairing sequence or propose a session on existing pairing. When responder client approves pairing, session is be proposed automatically by your client.
    /// - Parameter sessionPermissions: The session permissions the responder will be requested for.
    /// - Parameter topic: Optional parameter - use it if you already have an established pairing with peer client.
    /// - Returns: Pairing URI that should be shared with responder out of bound. Common way is to present it as a QR code. Pairing URI will be nil if you are going to establish a session on existing Pairing and `topic` function parameter was provided.
    public func connect(namespaces: Set<Namespace>, topic: String? = nil) async throws -> String? {
        logger.debug("Connecting Application")
        if let topic = topic {
            guard let pairing = pairingEngine.getSettledPairing(for: topic) else {
                throw WalletConnectError.noPairingMatchingTopic(topic)
            }
            logger.debug("Proposing session on existing pairing")
            try await pairingEngine.propose(pairingTopic: topic, namespaces: namespaces, relay: pairing.relay)
            return nil
        } else {
            let pairingURI = try await pairingEngine.create()
            try await pairingEngine.propose(pairingTopic: pairingURI.topic, namespaces: namespaces ,relay: pairingURI.relay)
            return pairingURI.absoluteString
        }
    }
    
    /// For responder to receive a session proposal from a proposer
    /// Responder should call this function in order to accept peer's pairing proposal and be able to subscribe for future session proposals.
    /// - Parameter uri: Pairing URI that is commonly presented as a QR code by a dapp.
    ///
    /// Should Error:
    /// - When URI is invalid format or missing params
    /// - When topic is already in use
    public func pair(uri: String) async throws {
        guard let pairingURI = WalletConnectURI(string: uri) else {
            throw WalletConnectError.malformedPairingURI
        }
        try await pairMathodEngine.pair(pairingURI)
    }
    
    /// For the responder to approve a session proposal.
    /// - Parameters:
    ///   - proposal: Session Proposal received from peer client in a WalletConnect delegate function: `didReceive(sessionProposal: Session.Proposal)`
    ///   - accounts: A Set of accounts that the dapp will be allowed to request methods executions on.
    ///   - methods: A Set of methods that the dapp will be allowed to request.
    ///   - events: A Set of events
    public func approve(
        proposalId: String,
        accounts: Set<Account>,
        namespaces: Set<Namespace>) {
            //TODO - accounts should be validated for matching namespaces
        guard let (sessionTopic, proposal) = pairingEngine.respondSessionPropose(proposerPubKey: proposalId) else {return}
            sessionEngine.settle(topic: sessionTopic, proposal: proposal, accounts: accounts, namespaces: namespaces)
    }
    
    /// For the responder to reject a session proposal.
    /// - Parameters:
    ///   - proposal: Session Proposal received from peer client in a WalletConnect delegate.
    ///   - reason: Reason why the session proposal was rejected. Conforms to CAIP25.
    public func reject(proposal: Session.Proposal, reason: RejectionReason) {
        pairingEngine.reject(proposal: proposal.proposal, reason: reason.internalRepresentation())
    }
    
    /// For the responder to update the accounts
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - accounts: Set of accounts that will be allowed to be used by the session after the update.
    public func updateAccounts(topic: String, accounts: Set<Account>) throws {
        try controllerSessionStateMachine.updateAccounts(topic: topic, accounts: accounts)
    }
    
    /// For the responder to update session methods
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - methods: Sets of methods that will replace existing ones.
    public func updateNamespaces(topic: String, namespaces: Set<Namespace>) throws {
        try controllerSessionStateMachine.updateNamespaces(topic: topic, namespaces: namespaces)
    }
    
    /// For controller to update expiry of a session
    /// - Parameters:
    ///   - topic: Topic of the Session, it can be a pairing or a session topic.
    ///   - ttl: Time in seconds that a target session is expected to be extended for. Must be greater than current time to expire and than 7 days
    public func updateExpiry(topic: String, ttl: Int64 = Session.defaultTimeToLive) throws {
        if sessionEngine.hasSession(for: topic) {
            try controllerSessionStateMachine.updateExpiry(topic: topic, by: ttl)
        }
    }
    
    /// For the proposer to send JSON-RPC requests to responding peer.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    public func request(params: Request) async throws {
        try await sessionEngine.request(params: params)
    }
    
    /// For the responder to respond on pending peer's session JSON-RPC Request
    /// - Parameters:
    ///   - topic: Topic of the session for which the request was received.
    ///   - response: Your JSON RPC response or an error.
    public func respond(topic: String, response: JsonRpcResult) {
        sessionEngine.respondSessionRequest(topic: topic, response: response)
    }
    
    /// Ping method allows to check if client's peer is online and is subscribing for your sequence topic
    ///
    ///  Should Error:
    ///  - When the session topic is not found
    ///  - When the response is neither result or error
    ///  - When the peer fails to respond within timeout
    ///
    /// - Parameters:
    ///   - topic: Topic of the sequence, it can be a pairing or a session topic.
    ///   - completion: Result will be success on response or error on timeout. -- TODO: timeout
    public func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        if pairingEngine.hasPairing(for: topic) {
            pairingEngine.ping(topic: topic) { result in
                completion(result)
            }
        } else if sessionEngine.hasSession(for: topic) {
            sessionEngine.ping(topic: topic) { result in
                completion(result)
            }
        }
    }
    
    /// For the proposer and responder to emits an event on the peer for an existing session
    ///
    /// When:  a client wants to emit an event to its peer client (eg. chain changed or tx replaced)
    ///
    /// Should Error:
    /// - When the session topic is not found
    /// - When the event params are invalid

    /// - Parameters:
    ///   - topic: Session topic
    ///   - params: Event Parameters
    ///   - completion: calls a handler upon completion
    public func emit(topic: String, event: Session.Event, chainId: Blockchain?, completion: ((Error?)->())?) {
        sessionEngine.emit(topic: topic, event: event.internalRepresentation(), chainId: chainId, completion: completion)
    }
    
    /// For the proposer and responder to terminate a session
    ///
    /// Should Error:
    /// - When the session topic is not found

    /// - Parameters:
    ///   - topic: Session topic that you want to delete
    ///   - reason: Reason of session deletion
    public func disconnect(topic: String, reason: Reason) async throws {
        try await sessionEngine.delete(topic: topic, reason: reason)
    }
    
    /// - Returns: All settled sessions that are active
    public func getSettledSessions() -> [Session] {
        sessionEngine.getAcknowledgedSessions()
    }
    
    /// - Returns: All settled pairings that are active
    public func getSettledPairings() -> [Pairing] {
        pairingEngine.getSettledPairings()
    }
    
    /// - Returns: Pending requests received with wc_sessionRequest
    /// - Parameter topic: topic representing session for which you want to get pending requests. If nil, you will receive pending requests for all active sessions.
    public func getPendingRequests(topic: String? = nil) -> [Request] {
        let pendingRequests: [Request] = history.getPending()
            .filter{$0.request.method == .sessionRequest}
            .compactMap {
                guard case let .sessionRequest(payloadRequest) = $0.request.params else {return nil}
                return Request(id: $0.id, topic: $0.topic, method: payloadRequest.request.method, params: payloadRequest.request.params, chainId: payloadRequest.chainId)
            }
        if let topic = topic {
            return pendingRequests.filter{$0.topic == topic}
        } else {
            return pendingRequests
        }
    }
    
    /// - Parameter id: id of a wc_sessionRequest jsonrpc request
    /// - Returns: json rpc record object for given id or nil if record for give id does not exits
    public func getSessionRequestRecord(id: Int64) -> WalletConnectUtils.JsonRpcRecord? {
        guard let record = history.get(id: id),
              case .sessionRequest(let payload) = record.request.params else {return nil}
        let request = WalletConnectUtils.JsonRpcRecord.Request(method: payload.request.method, params: payload.request.params)
        return WalletConnectUtils.JsonRpcRecord(id: record.id, topic: record.topic, request: request, response: record.response, chainId: record.chainId)
    }

    // MARK: - Private
    
    private func setUpEnginesCallbacks() {
        sessionEngine.onSessionSettle = { [unowned self] settledSession in
            delegate?.didSettle(session: settledSession)
        }
        pairingEngine.onSessionProposal = { [unowned self] proposal in
            delegate?.didReceive(sessionProposal: proposal)
        }
        pairingEngine.onSessionRejected = { [unowned self] proposal, reason in
            delegate?.didReject(proposal: proposal, reason: reason.publicRepresentation())
        }
        sessionEngine.onSessionRequest = { [unowned self] sessionRequest in
            delegate?.didReceive(sessionRequest: sessionRequest)
        }
        sessionEngine.onSessionDelete = { [unowned self] topic, reason in
            delegate?.didDelete(sessionTopic: topic, reason: reason.publicRepresentation())
        }
        controllerSessionStateMachine.onNamespacesUpdate = { [unowned self] topic, namespaces in
            delegate?.didUpdate(sessionTopic: topic, namespaces: namespaces)
        }
        controllerSessionStateMachine.onAccountsUpdate = { [unowned self] topic, accounts in
            delegate?.didUpdate(sessionTopic: topic, accounts: accounts)
        }
        controllerSessionStateMachine.onExpiryUpdate = { [unowned self] topic, expiry in
            delegate?.didUpdate(sessionTopic: topic, expiry: expiry)
        }
        nonControllerSessionStateMachine.onNamespacesUpdate = { [unowned self] topic, namespaces in
            delegate?.didUpdate(sessionTopic: topic, namespaces: namespaces)
        }
        nonControllerSessionStateMachine.onExpiryUpdate = { [unowned self] topic, expiry in
            delegate?.didUpdate(sessionTopic: topic, expiry: expiry)
        }
        nonControllerSessionStateMachine.onAccountsUpdate = { [unowned self] topic, accounts in
            delegate?.didUpdate(sessionTopic: topic, accounts: accounts)
        }
        sessionEngine.onEventReceived = { [unowned self] topic, event, chainId in
            delegate?.didReceive(event: event, sessionTopic: topic, chainId: chainId)
        }
        sessionEngine.onSessionResponse = { [unowned self] response in
            delegate?.didReceive(sessionResponse: response)
        }
        pairingEngine.onProposeResponse = { [unowned self] sessionTopic in
            sessionEngine.setSubscription(topic: sessionTopic)
        }
    }
}
