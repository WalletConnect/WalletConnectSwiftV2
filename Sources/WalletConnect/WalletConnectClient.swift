
import Foundation
import Relayer
import WalletConnectUtils
#if os(iOS)
import UIKit
#endif

/// An Object that expose public API to provide interactions with WalletConnect SDK
///
/// WalletConnect Client is not a singleton but once you create an instance, you should not deinitialise it. Usually only one instance of a client is required in the application.
///
/// ```swift
/// let metadata = AppMetadata(name: String?, description: String?, url: String?, icons: [String]?)
/// let client = WalletConnectClient(metadata: AppMetadata, projectId: String, isController: Bool, relayHost: String)
/// ```
///
/// - Parameters:
///     - delegate: The object that acts as the delegate of WalletConnect Client
///     - logger: An object for logging messages
public final class WalletConnectClient {
    public weak var delegate: WalletConnectClientDelegate?
    public let logger: ConsoleLogging
    private let metadata: AppMetadata
    private let isController: Bool
    private let pairingEngine: PairingEngine
    private let sessionEngine: SessionEngine
    private let relay: WalletConnectRelaying
    private let wakuRelay: NetworkRelaying
    private let crypto: Crypto
    private let secureStorage: SecureStorage
    private let pairingQueue = DispatchQueue(label: "com.walletconnect.sdk.client.pairing", qos: .userInitiated)
    private let history: JsonRpcHistory
#if os(iOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
#endif

    // MARK: - Initializers

    /// Initializes and returns newly created WalletConnect Client Instance. Establishes a network connection with the relay
    ///
    /// - Parameters:
    ///   - metadata: describes your application and will define pairing appearance in a web browser.
    ///   - projectId: an optional parameter used to access the public WalletConnect infrastructure. Go to `www.walletconnect.com` for info.
    ///   - isController: the peer that controls communication permissions for allowed chains, notification types and JSON-RPC request methods. Always true for a wallet.
    ///   - relayHost: proxy server host that your application will use to connect to Waku Network. If you register your project at `www.walletconnect.com` you can use `relay.walletconnect.com`
    ///   - keyValueStorage: by default WalletConnect SDK will store sequences in UserDefaults but if for some reasons you want to provide your own storage you can inject it here.
    ///   - clientName: if your app requires more than one client you are required to call them with different names to distinguish logs source and prefix storage keys.
    ///
    /// WalletConnect Client is not a singleton but once you create an instance, you should not deinitialise it. Usually only one instance of a client is required in the application.
    public convenience init(metadata: AppMetadata, projectId: String, isController: Bool, relayHost: String, keyValueStorage: KeyValueStorage = UserDefaults.standard, clientName: String? = nil) {
        self.init(metadata: metadata, projectId: projectId, isController: isController, relayHost: relayHost, logger: ConsoleLogger(loggingLevel: .off), keychain: KeychainStorage(uniqueIdentifier: clientName), keyValueStorage: keyValueStorage, clientName: clientName)
    }
    
    init(metadata: AppMetadata, projectId: String, isController: Bool, relayHost: String, logger: ConsoleLogging, keychain: KeychainStorage, keyValueStorage: KeyValueStorage, clientName: String? = nil) {
        self.metadata = metadata
        self.isController = isController
        self.logger = logger
//        try? keychain.deleteAll() // Use for cleanup while lifecycles are not handled yet, but FIXME whenever
        self.crypto = Crypto(keychain: keychain)
        self.secureStorage = SecureStorage(keychain: keychain)
        let relayUrl = WakuNetworkRelay.makeRelayUrl(host: relayHost, projectId: projectId)
        self.wakuRelay = WakuNetworkRelay(logger: logger, url: relayUrl, keyValueStorage: keyValueStorage, uniqueIdentifier: clientName ?? "")
        let serialiser = JSONRPCSerialiser(crypto: crypto)
        self.history = JsonRpcHistory(logger: logger, keyValueStore: KeyValueStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory(clientName: clientName ?? "_")))
        self.relay = WalletConnectRelay(networkRelayer: wakuRelay, jsonRpcSerialiser: serialiser, logger: logger, jsonRpcHistory: history)
        let pairingSequencesStore = PairingStorage(storage: SequenceStore<PairingSequence>(storage: keyValueStorage, identifier: StorageDomainIdentifiers.pairings(clientName: clientName ?? "_")))
        let sessionSequencesStore = SessionStorage(storage: SequenceStore<SessionSequence>(storage: keyValueStorage, identifier: StorageDomainIdentifiers.sessions(clientName: clientName ?? "_")))
        self.pairingEngine = PairingEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay, logger: logger), sequencesStore: pairingSequencesStore, isController: isController, metadata: metadata, logger: logger)

        self.sessionEngine = SessionEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay, logger: logger), sequencesStore: sessionSequencesStore, isController: isController, metadata: metadata, logger: logger)
        setUpEnginesCallbacks()
        subscribeNotificationCenter()
        registerBackgroundTask()
    }
    
    func registerBackgroundTask() {
#if os(iOS)
        self.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") { [weak self] in
            self?.endBackgroundTask()
        }
#endif
    }
    
    func endBackgroundTask() {
#if os(iOS)
        wakuRelay.disconnect(closeCode: .goingAway)
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
#endif
    }
    deinit {
        unsubscribeNotificationCenter()
    }
    
    // MARK: - Public interface

    /// For the Proposer to propose a session to a responder.
    /// Function will create pending pairing sequence or propose a session on existing pairing. When responder client approves pairing, session is be proposed automatically by your client.
    /// - Parameter sessionPermissions: The session permissions the responder will be requested for.
    /// - Parameter topic: Optional parameter - use it if you already have an established pairing with peer client.
    /// - Returns: Pairing URI that should be shared with responder out of bound. Common way is to present it as a QR code. Pairing URI will be nil if you are going to establish a session on existing Pairing and `topic` function parameter was provided.
    public func connect(sessionPermissions: Session.Permissions, topic: String? = nil) throws -> String? {
        logger.debug("Connecting Application")
        if let topic = topic {
            guard let pairing = pairingEngine.getSettledPairing(for: topic) else {
                throw WalletConnectError.InternalReason.noSequenceForTopic
            }
            logger.debug("Proposing session on existing pairing")
            let permissions = SessionPermissions(permissions: sessionPermissions)
            sessionEngine.proposeSession(settledPairing: Pairing(topic: pairing.topic, peer: nil), permissions: permissions, relay: pairing.relay)
            return nil
        } else {
            let permissions = SessionPermissions(permissions: sessionPermissions)
            guard let pairingURI = pairingEngine.propose(permissions: permissions) else {
                throw WalletConnectError.internal(.pairingProposalGenerationFailed)
            }
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
    public func pair(uri: String) throws {
        guard let pairingURI = WalletConnectURI(string: uri) else {
            throw WalletConnectError.internal(.malformedPairingURI)
        }
        try pairingQueue.sync {
            try pairingEngine.approve(pairingURI)
        }
    }
    
    /// For the responder to approve a session proposal.
    /// - Parameters:
    ///   - proposal: Session Proposal received from peer client in a WalletConnect delegate function: `didReceive(sessionProposal: Session.Proposal)`
    ///   - accounts: A Set of accounts that the dapp will be allowed to request methods executions on.
    public func approve(proposal: Session.Proposal, accounts: Set<String>) {
        sessionEngine.approve(proposal: proposal.proposal, accounts: accounts)
    }
    
    /// For the responder to reject a session proposal.
    /// - Parameters:
    ///   - proposal: Session Proposal received from peer client in a WalletConnect delegate.
    ///   - reason: Reason why the session proposal was rejected.
    public func reject(proposal: Session.Proposal, reason: Reason) {
        sessionEngine.reject(proposal: proposal.proposal, reason: reason)
    }
    
    /// For the responder to update the accounts
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - accounts: Set of accounts that will be allowed to be used by the session after the update.
    public func update(topic: String, accounts: Set<String>) {
        sessionEngine.update(topic: topic, accounts: accounts)
    }
    
    /// For the responder to upgrade session permissions
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be upgraded.
    ///   - permissions: Sets of permissions that will be combined with existing ones.
    public func upgrade(topic: String, permissions: Session.Permissions) {
        sessionEngine.upgrade(topic: topic, permissions: permissions)
    }
    
    /// For the proposer to send JSON-RPC requests to responding peer.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    ///   - completion: completion block will provide response from responding client
    public func request(params: Request, completion: @escaping (Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ()) {
        sessionEngine.request(params: params, completion: completion)
    }
    
    /// For the responder to respond on pending peer's session JSON-RPC Request
    /// - Parameters:
    ///   - topic: Topic of the session for which the request was received.
    ///   - response: Your JSON RPC response or an error.
    public func respond(topic: String, response: JsonRpcResponseTypes) {
        sessionEngine.respondSessionPayload(topic: topic, response: response)
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
    
    /// For the proposer and responder to emits a notification event on the peer for an existing session
    ///
    /// When:  a client wants to emit an event to its peer client (eg. chain changed or tx replaced)
    ///
    /// Should Error:
    /// - When the session topic is not found
    /// - When the notification params are invalid

    /// - Parameters:
    ///   - topic: Session topic
    ///   - params: Notification Parameters
    ///   - completion: calls a handler upon completion
    public func notify(topic: String, params: Session.Notification, completion: ((Error?)->())?) {
        sessionEngine.notify(topic: topic, params: params, completion: completion)
    }
    
    /// For the proposer and responder to terminate a session
    ///
    /// Should Error:
    /// - When the session topic is not found

    /// - Parameters:
    ///   - topic: Session topic that you want to delete
    ///   - reason: Reason of session deletion
    public func disconnect(topic: String, reason: Reason) {
        sessionEngine.delete(topic: topic, reason: reason)
    }
    
    /// - Returns: All settled sessions that are active
    public func getSettledSessions() -> [Session] {
        sessionEngine.getSettledSessions()
    }
    
    /// - Returns: All settled pairings that are active
    public func getSettledPairings() -> [Pairing] {
        pairingEngine.getSettledPairings()
    }
    
    public func getPendingRequests() -> [Request] {
        history.getPending()
            .filter{$0.request.method == .sessionPayload}
            .compactMap {
                guard case let .sessionPayload(payloadRequest) = $0.request.params else {return nil}
                return Request(id: $0.id, topic: $0.topic, method: payloadRequest.request.method, params: payloadRequest.request.params, chainId: payloadRequest.chainId)
            }
    }
    
    // MARK: - Private
    
    private func setUpEnginesCallbacks() {
        pairingEngine.onSessionProposal = { [unowned self] proposal in
            proposeSession(proposal: proposal)
        }
        pairingEngine.onPairingApproved = { [unowned self] settledPairing, permissions, relayOptions in
            delegate?.didSettle(pairing: settledPairing)
            sessionEngine.proposeSession(settledPairing: settledPairing, permissions: permissions, relay: relayOptions)
        }
        pairingEngine.onApprovalAcknowledgement = { [weak self] settledPairing in
            self?.delegate?.didSettle(pairing: settledPairing)
        }
        sessionEngine.onSessionApproved = { [unowned self] settledSession in
            let permissions = Session.Permissions.init(blockchains: settledSession.permissions.blockchains, methods: settledSession.permissions.methods)
            let session = Session(topic: settledSession.topic, peer: settledSession.peer, permissions: permissions)
            delegate?.didSettle(session: session)
        }
        sessionEngine.onApprovalAcknowledgement = { [weak self] session in
            self?.delegate?.didSettle(session: session)
        }
        sessionEngine.onSessionRejected = { [unowned self] pendingTopic, reason in
            delegate?.didReject(pendingSessionTopic: pendingTopic, reason: reason.toPublic())
        }
        sessionEngine.onSessionPayloadRequest = { [unowned self] sessionRequest in
            delegate?.didReceive(sessionRequest: sessionRequest)
        }
        sessionEngine.onSessionDelete = { [unowned self] topic, reason in
            delegate?.didDelete(sessionTopic: topic, reason: reason.toPublic())
        }
        sessionEngine.onSessionUpgrade = { [unowned self] topic, permissions in
            let upgradedPermissions = Session.Permissions(permissions: permissions)
            delegate?.didUpgrade(sessionTopic: topic, permissions: upgradedPermissions)
        }
        sessionEngine.onSessionUpdate = { [unowned self] topic, accounts in
            delegate?.didUpdate(sessionTopic: topic, accounts: accounts)
        }
        sessionEngine.onNotificationReceived = { [unowned self] topic, notification in
            delegate?.didReceive(notification: notification, sessionTopic: topic)
        }
        pairingEngine.onPairingUpdate = { [unowned self] topic, appMetadata in
            delegate?.didUpdate(pairingTopic: topic, appMetadata: appMetadata)
        }
    }
    
    private func proposeSession(proposal: SessionProposal) {
        let sessionProposal = Session.Proposal(
            proposer: proposal.proposer.metadata,
            permissions: Session.Permissions(
                blockchains: proposal.permissions.blockchain.chains,
                methods: proposal.permissions.jsonrpc.methods),
            proposal: proposal
        )
        delegate?.didReceive(sessionProposal: sessionProposal)
    }
    
    private func subscribeNotificationCenter() {
#if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
#endif
    }
    
    private func unsubscribeNotificationCenter() {
#if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
#endif
    }
    
    @objc
    private func appWillEnterForeground() {
        wakuRelay.connect()
        registerBackgroundTask()
    }

}
