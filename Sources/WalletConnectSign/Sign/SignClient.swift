import Foundation
import WalletConnectRelay
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
/// let client = SignClient(metadata: AppMetadata, projectId: String, relayHost: String)
/// ```
///
/// - Parameters:
///     - delegate: The object that acts as the delegate of WalletConnect Client
///     - logger: An object for logging messages
public final class SignClient {
    public weak var delegate: SignClientDelegate?

    public let logger: ConsoleLogging
    private let relayClient: RelayClient
    private let pairingEngine: PairingEngine
    private let pairEngine: PairEngine
    private let sessionEngine: SessionEngine
    private let approveEngine: ApproveEngine
    private let nonControllerSessionStateMachine: NonControllerSessionStateMachine
    private let controllerSessionStateMachine: ControllerSessionStateMachine
    private let history: JsonRpcHistory
    private let cleanupService: CleanupService
    private var publishers = [AnyCancellable]()

    // MARK: - Initialization

    init(logger: ConsoleLogging,
         relayClient: RelayClient,
         pairingEngine: PairingEngine,
         pairEngine: PairEngine,
         sessionEngine: SessionEngine,
         approveEngine: ApproveEngine,
         nonControllerSessionStateMachine: NonControllerSessionStateMachine,
         controllerSessionStateMachine: ControllerSessionStateMachine,
         history: JsonRpcHistory,
         cleanupService: CleanupService
    ) {
        self.logger = logger
        self.relayClient = relayClient
        self.pairingEngine = pairingEngine
        self.pairEngine = pairEngine
        self.sessionEngine = sessionEngine
        self.approveEngine = approveEngine
        self.nonControllerSessionStateMachine = nonControllerSessionStateMachine
        self.controllerSessionStateMachine = controllerSessionStateMachine
        self.history = history
        self.cleanupService = cleanupService

        setUpConnectionObserving()
        setUpEnginesCallbacks()
    }

    // MARK: - Public interface

    /// For the Proposer to propose a session to a responder.
    /// Function will create pending pairing sequence or propose a session on existing pairing. When responder client approves pairing, session is be proposed automatically by your client.
    /// - Parameter sessionPermissions: The session permissions the responder will be requested for.
    /// - Parameter topic: Optional parameter - use it if you already have an established pairing with peer client.
    /// - Returns: Pairing URI that should be shared with responder out of bound. Common way is to present it as a QR code. Pairing URI will be nil if you are going to establish a session on existing Pairing and `topic` function parameter was provided.
    public func connect(requiredNamespaces: [String: ProposalNamespace], topic: String? = nil) async throws -> String? {
        logger.debug("Connecting Application")
        if let topic = topic {
            guard let pairing = pairingEngine.getSettledPairing(for: topic) else {
                throw WalletConnectError.noPairingMatchingTopic(topic)
            }
            logger.debug("Proposing session on existing pairing")
            try await pairingEngine.propose(pairingTopic: topic, namespaces: requiredNamespaces, relay: pairing.relay)
            return nil
        } else {
            let pairingURI = try await pairingEngine.create()
            try await pairingEngine.propose(pairingTopic: pairingURI.topic, namespaces: requiredNamespaces, relay: pairingURI.relay)
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
        try await pairEngine.pair(pairingURI)
    }

    /// For the responder to approve a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal Public key received from peer client in a WalletConnect delegate function: `didReceive(sessionProposal: Session.Proposal)`
    ///   - accounts: A Set of accounts that the dapp will be allowed to request methods executions on.
    ///   - methods: A Set of methods that the dapp will be allowed to request.
    ///   - events: A Set of events
    public func approve(proposalId: String, namespaces: [String: SessionNamespace]) async throws {
        // TODO - accounts should be validated for matching namespaces BEFORE responding proposal
        try await approveEngine.approveProposal(proposerPubKey: proposalId, validating: namespaces)
    }

    /// For the responder to reject a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal Public key received from peer client in a WalletConnect delegate.
    ///   - reason: Reason why the session proposal was rejected. Conforms to CAIP25.
    public func reject(proposalId: String, reason: RejectionReason) async throws {
        try await approveEngine.reject(proposerPubKey: proposalId, reason: reason.internalRepresentation())
    }

    /// For the responder to update session namespaces
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - namespaces: Dictionary of namespaces that will replace existing ones.
    public func update(topic: String, namespaces: [String: SessionNamespace]) async throws {
        try await controllerSessionStateMachine.update(topic: topic, namespaces: namespaces)
    }

    /// For controller to update expiry of a session
    /// - Parameters:
    ///   - topic: Topic of the Session, it can be a pairing or a session topic.
    ///   - ttl: Time in seconds that a target session is expected to be extended for. Must be greater than current time to expire and than 7 days
    public func extend(topic: String) async throws {
        let ttl: Int64 = Session.defaultTimeToLive
        if sessionEngine.hasSession(for: topic) {
            try await controllerSessionStateMachine.extend(topic: topic, by: ttl)
        }
    }

    /// For the proposer to send JSON-RPC requests to responding peer.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    public func request(params: Request) async throws {
        try await sessionEngine.request(params)
    }

    /// For the responder to respond on pending peer's session JSON-RPC Request
    /// - Parameters:
    ///   - topic: Topic of the session for which the request was received.
    ///   - response: Your JSON RPC response or an error.
    public func respond(topic: String, response: JsonRpcResult) async throws {
        try await sessionEngine.respondSessionRequest(topic: topic, response: response)
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
    public func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> Void)) {
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
    public func emit(topic: String, event: Session.Event, chainId: Blockchain) async throws {
        try await sessionEngine.emit(topic: topic, event: event.internalRepresentation(), chainId: chainId)
    }

    /// For the proposer and responder to terminate a session
    ///
    /// Should Error:
    /// - When the session topic is not found

    /// - Parameters:
    ///   - topic: Session topic that you want to delete
    ///   - reason: Reason of session deletion
    public func disconnect(topic: String) async throws {
        try await sessionEngine.delete(topic: topic)
    }

    /// - Returns: All sessions
    public func getSessions() -> [Session] {
        sessionEngine.getSessions()
    }

    /// - Returns: All settled pairings that are active
    public func getSettledPairings() -> [Pairing] {
        pairingEngine.getSettledPairings()
    }

    /// - Returns: Pending requests received with wc_sessionRequest
    /// - Parameter topic: topic representing session for which you want to get pending requests. If nil, you will receive pending requests for all active sessions.
    public func getPendingRequests(topic: String? = nil) -> [Request] {
        let pendingRequests: [Request] = history.getPending()
            .filter {$0.request.method == .sessionRequest}
            .compactMap {
                guard case let .sessionRequest(payloadRequest) = $0.request.params else {return nil}
                return Request(id: $0.id, topic: $0.topic, method: payloadRequest.request.method, params: payloadRequest.request.params, chainId: payloadRequest.chainId)
            }
        if let topic = topic {
            return pendingRequests.filter {$0.topic == topic}
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
        approveEngine.onSessionProposal = { [unowned self] proposal in
            delegate?.didReceive(sessionProposal: proposal)
        }
        approveEngine.onSessionRejected = { [unowned self] proposal, reason in
            delegate?.didReject(proposal: proposal, reason: reason.publicRepresentation())
        }
        approveEngine.onSessionSettle = { [unowned self] settledSession in
            delegate?.didSettle(session: settledSession)
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
        controllerSessionStateMachine.onExtend = { [unowned self] topic, date in
            delegate?.didExtend(sessionTopic: topic, to: date)
        }
        nonControllerSessionStateMachine.onNamespacesUpdate = { [unowned self] topic, namespaces in
            delegate?.didUpdate(sessionTopic: topic, namespaces: namespaces)
        }
        nonControllerSessionStateMachine.onExtend = { [unowned self] topic, date in
            delegate?.didExtend(sessionTopic: topic, to: date)
        }
        sessionEngine.onEventReceived = { [unowned self] topic, event, chainId in
            delegate?.didReceive(event: event, sessionTopic: topic, chainId: chainId)
        }
        sessionEngine.onSessionResponse = { [unowned self] response in
            delegate?.didReceive(sessionResponse: response)
        }
    }

    private func setUpConnectionObserving() {
        relayClient.socketConnectionStatusPublisher.sink { [weak self] status in
            self?.delegate?.didChangeSocketConnectionStatus(status)
        }.store(in: &publishers)
    }

#if DEBUG
    /// Delete all stored data sach as: pairings, sessions, keys
    ///
    /// - Note: Doesn't unsubscribe from topics
    public func cleanup() throws {
        try cleanupService.cleanup()
    }
#endif
}
