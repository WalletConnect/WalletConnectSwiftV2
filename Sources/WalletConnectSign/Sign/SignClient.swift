import Foundation
import Combine

/// WalletConnect Sign Client
///
/// Cannot be instantiated outside of the SDK
///
/// Access via `Sign.instance`
public final class SignClient: SignClientProtocol {

    enum Errors: Error {
        case sessionForTopicNotFound
    }

    // MARK: - Public Properties

    /// Publisher that sends session proposal
    ///
    /// event is emited on responder client only
    public var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> {
        sessionProposalPublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends session request
    ///
    /// In most cases event will be emited on wallet
    public var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        sessionEngine.sessionRequestPublisher
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

    /// Publisher that sends session topic when session ping received
    ///
    /// Event will be emited on controller and non-controller clients.
    public var pingResponsePublisher: AnyPublisher<String, Never> {
        pingResponsePublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends sessions on every sessions update
    ///
    /// Event will be emited on controller and non-controller clients.
    public var sessionsPublisher: AnyPublisher<[Session], Never> {
        sessionsPublisherSubject.eraseToAnyPublisher()
    }

    //------------------------------------AUTH---------------------------------------
    /// Publisher that sends authentication requests
    ///
    /// Wallet should subscribe on events in order to receive auth requests.
    public var authenticateRequestPublisher: AnyPublisher<(request: AuthenticationRequest, context: VerifyContext?), Never> {
        return authRequestPublisherSubject
            .handleEvents(receiveSubscription: { [unowned self] _ in
                authRequestSubscribersTracking.increment()
            }, receiveCancel: { [unowned self] in
                authRequestSubscribersTracking.decrement()
            })
            .eraseToAnyPublisher()
    }

    /// Publisher that sends authentication responses
    ///
    /// App should subscribe for events in order to receive CACAO object with a signature matching authentication request.
    ///
    /// Emited result may be an error.
    public var authResponsePublisher: AnyPublisher<(id: RPCID, result: Result<(Session?, [Cacao]), AuthError>), Never> {
        authResposeSubscriber.authResponsePublisher
    }
    //---------------------------------------------------------------------------------
    public var logsPublisher: AnyPublisher<Log, Never> {
        return logger.logsPublisher
    }

    /// Publisher that sends session proposal expiration
    public var sessionProposalExpirationPublisher: AnyPublisher<Session.Proposal, Never> {
        return proposalExpiryWatcher.sessionProposalExpirationPublisher
    }

    public var pendingProposalsPublisher: AnyPublisher<[(proposal: Session.Proposal, context: VerifyContext?)], Never> {
        return pendingProposalsProvider.pendingProposalsPublisher
    }

    public var requestExpirationPublisher: AnyPublisher<RPCID, Never> {
        return requestsExpiryWatcher.requestExpirationPublisher
    }


    /// An object that loggs SDK's errors and info messages
    public let logger: ConsoleLogging

    // MARK: - Private properties

    private let pairingClient: PairingClient
    private let networkingClient: NetworkingInteractor
    private let sessionEngine: SessionEngine
    private let approveEngine: ApproveEngine
    private let disconnectService: DisconnectService
    private let sessionPingService: SessionPingService
    private let nonControllerSessionStateMachine: NonControllerSessionStateMachine
    private let controllerSessionStateMachine: ControllerSessionStateMachine
    private let sessionExtendRequester: SessionExtendRequester
    private let sessionExtendRequestSubscriber: SessionExtendRequestSubscriber
    private let sessionExtendResponseSubscriber: SessionExtendResponseSubscriber
    private let appProposeService: AppProposeService
    private let historyService: HistoryService
    private let cleanupService: SignCleanupService
    private let pendingRequestsProvider: PendingRequestsProvider
    private let proposalExpiryWatcher: ProposalExpiryWatcher
    private let pendingProposalsProvider: PendingProposalsProvider
    private let requestsExpiryWatcher: RequestsExpiryWatcher

    //Auth
    private let appRequestService: SessionAuthRequestService
    private let authResposeSubscriber: AuthResponseSubscriber
    private let authRequestSubscriber: AuthRequestSubscriber
    private let approveSessionAuthenticateDispatcher: ApproveSessionAuthenticateDispatcher
    private let authResponseTopicResubscriptionService: AuthResponseTopicResubscriptionService

    private let sessionProposalPublisherSubject = PassthroughSubject<(proposal: Session.Proposal, context: VerifyContext?), Never>()
    private let socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    private let sessionSettlePublisherSubject = PassthroughSubject<Session, Never>()
    private let sessionDeletePublisherSubject = PassthroughSubject<(String, Reason), Never>()
    private let sessionResponsePublisherSubject = PassthroughSubject<Response, Never>()
    private let sessionRejectionPublisherSubject = PassthroughSubject<(Session.Proposal, Reason), Never>()
    private let sessionUpdatePublisherSubject = PassthroughSubject<(sessionTopic: String, namespaces: [String: SessionNamespace]), Never>()
    private let sessionEventPublisherSubject = PassthroughSubject<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never>()
    private let sessionExtendPublisherSubject = PassthroughSubject<(sessionTopic: String, date: Date), Never>()
    private let pingResponsePublisherSubject = PassthroughSubject<String, Never>()
    private let sessionsPublisherSubject = PassthroughSubject<[Session], Never>()
    private var authRequestPublisherSubject = PassthroughSubject<(request: AuthenticationRequest, context: VerifyContext?), Never>()
    private let authRequestSubscribersTracking: AuthRequestSubscribersTracking
    private let authenticateTransportTypeSwitcher: AuthenticateTransportTypeSwitcher


    // Link Mode
    private let linkAuthRequester: LinkAuthRequester
    private let linkAuthRequestSubscriber: LinkAuthRequestSubscriber
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
    private let sessionRequestDispatcher: SessionRequestDispatcher
    private let linkSessionRequestSubscriber: LinkSessionRequestSubscriber
    private let sessionResponderDispatcher: SessionResponderDispatcher
    private let linkSessionRequestResponseSubscriber: LinkSessionRequestResponseSubscriber
    private let messageVerifier: MessageVerifier

    private var publishers = Set<AnyCancellable>()

    // MARK: - Initialization

    init(logger: ConsoleLogging,
         networkingClient: NetworkingInteractor,
         sessionEngine: SessionEngine,
         approveEngine: ApproveEngine,
         sessionPingService: SessionPingService,
         nonControllerSessionStateMachine: NonControllerSessionStateMachine,
         controllerSessionStateMachine: ControllerSessionStateMachine,
         sessionExtendRequester: SessionExtendRequester,
         sessionExtendRequestSubscriber: SessionExtendRequestSubscriber,
         sessionExtendResponseSubscriber: SessionExtendResponseSubscriber,
         appProposeService: AppProposeService,
         disconnectService: DisconnectService,
         historyService: HistoryService,
         cleanupService: SignCleanupService,
         pairingClient: PairingClient,
         appRequestService: SessionAuthRequestService,
         appRespondSubscriber: AuthResponseSubscriber,
         authRequestSubscriber: AuthRequestSubscriber,
         approveSessionAuthenticateDispatcher: ApproveSessionAuthenticateDispatcher,
         pendingRequestsProvider: PendingRequestsProvider,
         proposalExpiryWatcher: ProposalExpiryWatcher,
         pendingProposalsProvider: PendingProposalsProvider,
         requestsExpiryWatcher: RequestsExpiryWatcher,
         authResponseTopicResubscriptionService: AuthResponseTopicResubscriptionService,
         authRequestSubscribersTracking: AuthRequestSubscribersTracking,
         linkAuthRequester: LinkAuthRequester,
         linkAuthRequestSubscriber: LinkAuthRequestSubscriber,
         linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
         sessionRequestDispatcher: SessionRequestDispatcher,
         linkSessionRequestSubscriber: LinkSessionRequestSubscriber,
         sessionResponderDispatcher: SessionResponderDispatcher,
         linkSessionRequestResponseSubscriber: LinkSessionRequestResponseSubscriber,
         authenticateTransportTypeSwitcher: AuthenticateTransportTypeSwitcher,
         messageVerifier: MessageVerifier
    ) {
        self.logger = logger
        self.networkingClient = networkingClient
        self.sessionEngine = sessionEngine
        self.approveEngine = approveEngine
        self.sessionPingService = sessionPingService
        self.nonControllerSessionStateMachine = nonControllerSessionStateMachine
        self.controllerSessionStateMachine = controllerSessionStateMachine
        self.sessionExtendRequester = sessionExtendRequester
        self.sessionExtendRequestSubscriber = sessionExtendRequestSubscriber
        self.sessionExtendResponseSubscriber = sessionExtendResponseSubscriber
        self.appProposeService = appProposeService
        self.historyService = historyService
        self.cleanupService = cleanupService
        self.disconnectService = disconnectService
        self.pairingClient = pairingClient
        self.appRequestService = appRequestService
        self.authRequestSubscriber = authRequestSubscriber
        self.approveSessionAuthenticateDispatcher = approveSessionAuthenticateDispatcher
        self.authResposeSubscriber = appRespondSubscriber
        self.pendingRequestsProvider = pendingRequestsProvider
        self.proposalExpiryWatcher = proposalExpiryWatcher
        self.pendingProposalsProvider = pendingProposalsProvider
        self.requestsExpiryWatcher = requestsExpiryWatcher
        self.authResponseTopicResubscriptionService = authResponseTopicResubscriptionService
        self.authRequestSubscribersTracking = authRequestSubscribersTracking
        self.linkAuthRequester = linkAuthRequester
        self.linkAuthRequestSubscriber = linkAuthRequestSubscriber
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.sessionRequestDispatcher = sessionRequestDispatcher
        self.linkSessionRequestSubscriber = linkSessionRequestSubscriber
        self.sessionResponderDispatcher = sessionResponderDispatcher
        self.linkSessionRequestResponseSubscriber = linkSessionRequestResponseSubscriber
        self.authenticateTransportTypeSwitcher = authenticateTransportTypeSwitcher
        self.messageVerifier = messageVerifier

        setUpConnectionObserving()
        setUpEnginesCallbacks()
    }

    // MARK: - Public interface

    /// For a dApp to propose a session to a wallet.
    /// Function will create pairing and propose session.
    /// - Parameters:
    ///   - requiredNamespaces: required namespaces for a session
    /// - Returns: Pairing URI that should be shared with responder out of bound. Common way is to present it as a QR code.
    public func connect(
        requiredNamespaces: [String: ProposalNamespace],
        optionalNamespaces: [String: ProposalNamespace]? = nil,
        sessionProperties: [String: String]? = nil
    ) async throws -> WalletConnectURI {
        logger.debug("Connecting Application")
        let pairingURI = try await pairingClient.create()
        try await appProposeService.propose(
            pairingTopic: pairingURI.topic,
            namespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: sessionProperties,
            relay: RelayProtocolOptions(protocol: "irn", data: nil)
        )
        return pairingURI
    }

    //---------------------------------------AUTH-----------------------------------

    /// For a dApp to propose an authenticated session to a wallet.
    public func authenticate(
        _ params: AuthRequestParams,
        walletUniversalLink: String? = nil
    ) async throws -> WalletConnectURI? {
        return try await authenticateTransportTypeSwitcher.authenticate(params, walletUniversalLink: walletUniversalLink)
    }


    #if DEBUG
    @discardableResult public func authenticateLinkMode(
        _ params: AuthRequestParams,
        walletUniversalLink: String
    ) async throws -> String {
        return try await linkAuthRequester.request(params: params, walletUniversalLink: walletUniversalLink)
    }
    #endif

    public func dispatchEnvelope(_ envelope: String) throws {
        try linkEnvelopesDispatcher.dispatchEnvelope(envelope)
    }



    /// For a wallet to respond on authentication request
    /// - Parameters:
    ///   - requestId: authentication request id
    ///   - signature: CACAO signature of requested message
    public func approveSessionAuthenticate(requestId: RPCID, auths: [Cacao]) async throws -> Session? {
        let (session, _) = try await approveSessionAuthenticateDispatcher.approveSessionAuthenticate(requestId: requestId, auths: auths)
        return session
    }

    /// the function returns envelope for link mode testing
    #if DEBUG
    func approveSessionAuthenticateLinkMode(requestId: RPCID, auths: [Cacao]) async throws -> (Session?, String) {
        let (session, envelope) = try await approveSessionAuthenticateDispatcher.approveSessionAuthenticate(requestId: requestId, auths: auths)
        return (session, envelope!)
    }
    #endif

    /// For wallet to reject authentication request
    /// - Parameter requestId: authentication request id
    public func rejectSession(requestId: RPCID) async throws {
        try await approveSessionAuthenticateDispatcher.respondError(requestId: requestId)
    }


    /// Query pending authentication requests
    /// - Returns: Pending authentication requests
    public func getPendingAuthRequests() throws -> [(AuthenticationRequest, VerifyContext?)] {
        return try pendingRequestsProvider.getPendingRequests()
    }

    public func buildSignedAuthObject(authPayload: AuthPayload, signature: CacaoSignature, account: Account) throws -> AuthObject {
        try CacaosBuilder.makeCacao(authPayload: authPayload, signature: signature, account: account)
    }

    public func buildAuthPayload(payload: AuthPayload, supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> AuthPayload {
        try AuthPayloadBuilder.build(payload: payload, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)
    }

    // MARK: - SIWE

    public func formatAuthMessage(payload: AuthPayload, account: Account) throws -> String {
        let cacaoPayload = try CacaoPayloadBuilder.makeCacaoPayload(authPayload: payload, account: account)
        return try SIWEFromCacaoPayloadFormatter().formatMessage(from: cacaoPayload)
    }

    public func verifySIWE(signature: String, message: String, address: String, chainId: String) async throws {
        try await messageVerifier.verify(signature: signature, message: message, address: address, chainId: chainId)
    }

    //-----------------------------------------------------------------------------------

    /// For a wallet to approve a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal id
    ///   - namespaces: namespaces for given session, needs to contain at least required namespaces proposed by dApp.
    public func approve(proposalId: String, namespaces: [String: SessionNamespace], sessionProperties: [String: String]? = nil) async throws -> Session {
        try await approveEngine.approveProposal(proposerPubKey: proposalId, validating: namespaces, sessionProperties: sessionProperties)
    }

    /// For the wallet to reject a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal id
    ///   - reason: Reason why the session proposal has been rejected. Conforms to CAIP25.
    public func rejectSession(proposalId: String, reason: RejectionReason) async throws {
        try await approveEngine.reject(proposerPubKey: proposalId, reason: reason.internalRepresentation())
    }

    /// For the wallet to update session namespaces
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - namespaces: Dictionary of namespaces that will replace existing ones.
    public func update(topic: String, namespaces: [String: SessionNamespace]) async throws {
        try await controllerSessionStateMachine.update(topic: topic, namespaces: namespaces)
    }

    /// For dapp and wallet to extend a session to 7 days
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be extended.
    public func extend(topic: String) async throws {
        let ttl: Int64 = Session.defaultTimeToLive
        if sessionEngine.hasSession(for: topic) {
            try await sessionExtendRequester.extend(topic: topic, by: ttl)
        }
    }

    /// For a dApp to send JSON-RPC requests to wallet.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    public func request(params: Request) async throws {
        _ = try await sessionRequestDispatcher.request(params)
    }

    /// the function returns envelope for link mode testing
#if DEBUG
    public func requestLinkMode(params: Request) async throws -> String? {
        return try await sessionRequestDispatcher.request(params)
    }
#endif

    /// For the wallet to respond on pending dApp's JSON-RPC request
    /// - Parameters:
    ///   - topic: Topic of the session for which the request was received.
    ///   - requestId: RPC request ID
    ///   - response: Your JSON RPC response or an error.
    public func respond(topic: String, requestId: RPCID, response: RPCResult) async throws {
        _ = try await sessionResponderDispatcher.respondSessionRequest(topic: topic, requestId: requestId, response: response)
    }
    /// the function returns envelope for link mode testing

#if DEBUG
    public func respondLinkMode(topic: String, requestId: RPCID, response: RPCResult) async throws -> String? {
        return try await sessionResponderDispatcher.respondSessionRequest(topic: topic, requestId: requestId, response: response)
    }
#endif

    /// Ping method allows to check if peer client is online and is subscribing for given topic
    ///
    ///  Should Error:
    ///  - When the session topic is not found
    ///
    /// - Parameters:
    ///   - topic: Topic of a session
    public func ping(topic: String) async throws {
        guard sessionEngine.hasSession(for: topic) else { throw Errors.sessionForTopicNotFound }
        try await sessionPingService.ping(topic: topic)
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
        try await disconnectService.disconnect(topic: topic)
    }

    /// Query sessions
    /// - Returns: All sessions
    public func getSessions() -> [Session] {
        sessionEngine.getSessions()
    }

    /// Query pending requests
    /// - Returns: Pending requests received from peer with `wc_sessionRequest` protocol method
    /// - Parameter topic: topic representing session for which you want to get pending requests. If nil, you will receive pending requests for all active sessions.
    public func getPendingRequests(topic: String? = nil) -> [(request: Request, context: VerifyContext?)] {
        if let topic = topic {
            return historyService.getPendingRequests(topic: topic)
        } else {
            return historyService.getPendingRequests()
        }
    }

    public func getPendingProposals(topic: String? = nil) -> [(proposal: Session.Proposal, context: VerifyContext?)] {
        pendingProposalsProvider.getPendingProposals()
    }

    /// Delete all stored data such as: pairings, sessions, keys
    ///
    /// - Note: Will unsubscribe from all topics
    public func cleanup() async throws {
        try await cleanupService.cleanup()
    }

#if DEBUG
    /// Delete all stored data such as: pairings, sessions, keys
    ///
    /// - Note: Doesn't unsubscribe from topics
    public func cleanup() throws {
        try cleanupService.cleanup()
    }
#endif

    public func setLogging(level: LoggingLevel) {
        logger.setLogging(level: level)
    }

    // MARK: - Private

    private func setUpEnginesCallbacks() {
        approveEngine.onSessionProposal = { [unowned self] (proposal, context) in
            sessionProposalPublisherSubject.send((proposal, context))
        }
        approveEngine.onSessionRejected = { [unowned self] proposal, reason in
            sessionRejectionPublisherSubject.send((proposal, reason))
        }
        approveEngine.onSessionSettle = { [unowned self] settledSession in
            sessionSettlePublisherSubject.send(settledSession)
        }
        sessionEngine.onSessionDelete = { [unowned self] topic, reason in
            sessionDeletePublisherSubject.send((topic, reason))
        }
        controllerSessionStateMachine.onNamespacesUpdate = { [unowned self] topic, namespaces in
            sessionUpdatePublisherSubject.send((topic, namespaces))
        }
        nonControllerSessionStateMachine.onNamespacesUpdate = { [unowned self] topic, namespaces in
            sessionUpdatePublisherSubject.send((topic, namespaces))
        }
        sessionExtendRequestSubscriber.onExtend = { [unowned self] topic, date in
            sessionExtendPublisherSubject.send((topic, date))
        }
        sessionExtendResponseSubscriber.onExtend = { [unowned self] topic, date in
            sessionExtendPublisherSubject.send((topic, date))
        }
        sessionEngine.onEventReceived = { [unowned self] topic, event, chainId in
            sessionEventPublisherSubject.send((event, topic, chainId))
        }
        sessionEngine.onSessionResponse = { [unowned self] response in
            sessionResponsePublisherSubject.send(response)
        }
        sessionPingService.onResponse = { [unowned self] topic in
            pingResponsePublisherSubject.send(topic)
        }
        sessionEngine.onSessionsUpdate = { [unowned self] sessions in
            sessionsPublisherSubject.send(sessions)
        }
        authRequestSubscriber.onRequest = { [unowned self] request in
            authRequestPublisherSubject.send(request)
        }
        linkAuthRequestSubscriber.onRequest = { [unowned self] request in
            authRequestPublisherSubject.send(request)
        }
        linkSessionRequestResponseSubscriber.onSessionResponse = { [unowned self] response in
            sessionResponsePublisherSubject.send(response)
        }
    }

    private func setUpConnectionObserving() {
        networkingClient.socketConnectionStatusPublisher.sink { [weak self] status in
            self?.socketConnectionStatusPublisherSubject.send(status)
        }.store(in: &publishers)
    }
}

