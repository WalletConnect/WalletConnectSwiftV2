import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import Combine

/// WalletConnect Sign Client
///
/// Cannot be instantiated outside of the SDK
///
/// Access via `Sign.instance`
public final class SignClient {

    // MARK: - Public Properties

    /// Publisher that sends session proposal
    ///
    /// event is emited on responder client only
    public var sessionProposalPublisher: AnyPublisher<Session.Proposal, Never> {
        sessionProposalPublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends session request
    ///
    /// In most cases event will be emited on wallet
    public var sessionRequestPublisher: AnyPublisher<Request, Never> {
        sessionRequestPublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends web socket connection status
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends session when one is settled
    ///
    /// Event is emited on proposer and responder client when both communicating peers have successfully established a session.
    public var sessionSettlePublisher: AnyPublisher<Session, Never> {
        sessionSettlePublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends deleted session topic
    ///
    /// Event can be emited on any type of the client.
    public var sessionDeletePublisher: AnyPublisher<(String, Reason), Never> {
        sessionDeletePublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends response for session request
    ///
    /// In most cases that event will be emited on dApp client.
    public var sessionResponsePublisher: AnyPublisher<Response, Never> {
        sessionResponsePublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends session proposal that has been rejected
    ///
    /// Event will be emited on dApp client only.
    public var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        sessionRejectionPublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends session topic and namespaces on session update
    ///
    /// Event will be emited controller and non-controller client when both communicating peers have successfully updated methods requested by the controller client.
    public var sessionUpdatePublisher: AnyPublisher<(sessionTopic: String, namespaces: [String: SessionNamespace]), Never> {
        sessionUpdatePublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends session event
    ///
    /// Event will be emited on dApp client only
    public var sessionEventPublisher: AnyPublisher<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never> {
        sessionEventPublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends session topic when session is extended
    ///
    /// Event will be emited on controller and non-controller clients.
    public var sessionExtendPublisher: AnyPublisher<(sessionTopic: String, date: Date), Never> {
        sessionExtendPublisherSubject.eraseToAnyPublisher()
    }

    /// An object that loggs SDK's errors and info messages
    public let logger: ConsoleLogging

    // MARK: - Private properties

    private let relayClient: RelayClient
    private let pairingEngine: PairingEngine
    private let pairEngine: PairEngine
    private let sessionEngine: SessionEngine
    private let approveEngine: ApproveEngine
    private let nonControllerSessionStateMachine: NonControllerSessionStateMachine
    private let controllerSessionStateMachine: ControllerSessionStateMachine
    private let history: JsonRpcHistory
    private let cleanupService: CleanupService

    private let sessionProposalPublisherSubject = PassthroughSubject<Session.Proposal, Never>()
    private let sessionRequestPublisherSubject = PassthroughSubject<Request, Never>()
    private let socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    private let sessionSettlePublisherSubject = PassthroughSubject<Session, Never>()
    private let sessionDeletePublisherSubject = PassthroughSubject<(String, Reason), Never>()
    private let sessionResponsePublisherSubject = PassthroughSubject<Response, Never>()
    private let sessionRejectionPublisherSubject = PassthroughSubject<(Session.Proposal, Reason), Never>()
    private let sessionUpdatePublisherSubject = PassthroughSubject<(sessionTopic: String, namespaces: [String: SessionNamespace]), Never>()
    private let sessionEventPublisherSubject = PassthroughSubject<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never>()
    private let sessionExtendPublisherSubject = PassthroughSubject<(sessionTopic: String, date: Date), Never>()

    private var publishers = Set<AnyCancellable>()

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

    /// For a dApp to propose a session to a wallet.
    /// Function will create pairing and propose session or propose a session on existing pairing.
    /// - Parameters:
    ///   - requiredNamespaces: required namespaces for a session
    ///   - topic: Optional parameter - use it if you already have an established pairing with peer client.
    /// - Returns: Pairing URI that should be shared with responder out of bound. Common way is to present it as a QR code. Pairing URI will be nil if you are going to establish a session on existing Pairing and `topic` function parameter was provided.
    public func connect(requiredNamespaces: [String: ProposalNamespace], topic: String? = nil) async throws -> WalletConnectURI? {
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
            return pairingURI
        }
    }

    /// For wallet to receive a session proposal from a dApp
    /// Responder should call this function in order to accept peer's pairing and be able to subscribe for future session proposals.
    /// - Parameter uri: Pairing URI that is commonly presented as a QR code by a dapp.
    ///
    /// Should Error:
    /// - When URI has invalid format or missing params
    /// - When topic is already in use
    public func pair(uri: WalletConnectURI) async throws {
        guard uri.api == .sign else {
            throw WalletConnectError.pairingUriWrongApiParam
        }
        try await pairEngine.pair(uri)
    }

    /// For a wallet to approve a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal id
    ///   - namespaces: namespaces for given session, needs to contain at least required namespaces proposed by dApp.
    public func approve(proposalId: String, namespaces: [String: SessionNamespace]) async throws {
        try await approveEngine.approveProposal(proposerPubKey: proposalId, validating: namespaces)
    }

    /// For the wallet to reject a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal id
    ///   - reason: Reason why the session proposal has been rejected. Conforms to CAIP25.
    public func reject(proposalId: String, reason: RejectionReason) async throws {
        try await approveEngine.reject(proposerPubKey: proposalId, reason: reason.internalRepresentation())
    }

    /// For the wallet to update session namespaces
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - namespaces: Dictionary of namespaces that will replace existing ones.
    public func update(topic: String, namespaces: [String: SessionNamespace]) async throws {
        try await controllerSessionStateMachine.update(topic: topic, namespaces: namespaces)
    }

    /// For wallet to extend a session to 7 days
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be extended.
    public func extend(topic: String) async throws {
        let ttl: Int64 = Session.defaultTimeToLive
        if sessionEngine.hasSession(for: topic) {
            try await controllerSessionStateMachine.extend(topic: topic, by: ttl)
        }
    }

    /// For a dApp to send JSON-RPC requests to wallet.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    public func request(params: Request) async throws {
        try await sessionEngine.request(params)
    }

    /// For the wallet to respond on pending dApp's JSON-RPC request
    /// - Parameters:
    ///   - topic: Topic of the session for which the request was received.
    ///   - response: Your JSON RPC response or an error.
    public func respond(topic: String, response: JsonRpcResult) async throws {
        try await sessionEngine.respondSessionRequest(topic: topic, response: response)
    }

    /// Ping method allows to check if peer client is online and is subscribing for given topic
    ///
    ///  Should Error:
    ///  - When the session topic is not found
    ///  - When the response is neither result or error
    ///
    /// - Parameters:
    ///   - topic: Topic of a session or a pairing
    ///   - completion: Result will be success on response or an error
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

    /// For the wallet to emit an event to a dApp
    ///
    /// When a client wants to emit an event to its peer client (eg. chain changed or tx replaced)
    ///
    /// Should Error:
    /// - When the session topic is not found
    /// - When the event params are invalid
    /// - Parameters:
    ///   - topic: Session topic
    ///   - event: session event
    ///   - chainId: CAIP-2 chain
    public func emit(topic: String, event: Session.Event, chainId: Blockchain) async throws {
        try await sessionEngine.emit(topic: topic, event: event.internalRepresentation(), chainId: chainId)
    }

    /// For a wallet and a dApp to terminate a session
    ///
    /// Should Error:
    /// - When the session topic is not found
    /// - Parameters:
    ///   - topic: Session topic that you want to delete
    public func disconnect(topic: String) async throws {
        try await sessionEngine.delete(topic: topic)
    }

    /// Query sessions
    /// - Returns: All sessions
    public func getSessions() -> [Session] {
        sessionEngine.getSessions()
    }

    /// Query pairings
    /// - Returns: All pairings
    public func getPairings() -> [Pairing] {
        pairingEngine.getPairings()
    }

    /// Query pending requests
    /// - Returns: Pending requests received from peer with `wc_sessionRequest` protocol method
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

#if DEBUG
    /// Delete all stored data such as: pairings, sessions, keys
    ///
    /// - Note: Doesn't unsubscribe from topics
    public func cleanup() throws {
        try cleanupService.cleanup()
    }
#endif

    // MARK: - Private

    private func setUpEnginesCallbacks() {
        approveEngine.onSessionProposal = { [unowned self] proposal in
            sessionProposalPublisherSubject.send(proposal)
        }
        approveEngine.onSessionRejected = { [unowned self] proposal, reason in
            sessionRejectionPublisherSubject.send((proposal, reason.publicRepresentation()))
        }
        approveEngine.onSessionSettle = { [unowned self] settledSession in
            sessionSettlePublisherSubject.send(settledSession)
        }
        sessionEngine.onSessionRequest = { [unowned self] sessionRequest in
            sessionRequestPublisherSubject.send(sessionRequest)
        }
        sessionEngine.onSessionDelete = { [unowned self] topic, reason in
            sessionDeletePublisherSubject.send((topic, reason.publicRepresentation()))
        }
        controllerSessionStateMachine.onNamespacesUpdate = { [unowned self] topic, namespaces in
            sessionUpdatePublisherSubject.send((topic, namespaces))
        }
        controllerSessionStateMachine.onExtend = { [unowned self] topic, date in
            sessionExtendPublisherSubject.send((topic, date))
        }
        nonControllerSessionStateMachine.onNamespacesUpdate = { [unowned self] topic, namespaces in
            sessionUpdatePublisherSubject.send((topic, namespaces))
        }
        nonControllerSessionStateMachine.onExtend = { [unowned self] topic, date in
            sessionExtendPublisherSubject.send((topic, date))
        }
        sessionEngine.onEventReceived = { [unowned self] topic, event, chainId in
            sessionEventPublisherSubject.send((event, topic, chainId))
        }
        sessionEngine.onSessionResponse = { [unowned self] response in
            sessionResponsePublisherSubject.send(response)
        }
    }

    private func setUpConnectionObserving() {
        relayClient.socketConnectionStatusPublisher.sink { [weak self] status in
            self?.socketConnectionStatusPublisherSubject.send(status)
        }.store(in: &publishers)
    }
}
