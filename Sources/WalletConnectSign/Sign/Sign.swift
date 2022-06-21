import Foundation
import WalletConnectUtils
import WalletConnectRelay
import Combine

public typealias Account = WalletConnectUtils.Account
public typealias Blockchain = WalletConnectUtils.Blockchain

public class Sign {
    public static let instance = Sign()

    private static var config: Config?
    private let client: SignClient
    private let relayClient: RelayClient

    private init() {
        guard let config = Sign.config else {
            fatalError("Error - you must call configure(_:) before accessing the shared instance.")
        }
        relayClient = RelayClient(relayHost: "relay.walletconnect.com", projectId: config.projectId, socketConnectionType: config.socketConnectionType)
        client = SignClient(metadata: config.metadata, relayClient: relayClient)
        client.delegate = self
    }

    static public func configure(_ config: Config) {
        Sign.config = config
    }

    var sessionProposalPublisherSubject = PassthroughSubject<Session.Proposal, Never>()
    public var sessionProposalPublisher: AnyPublisher<Session.Proposal, Never> {
        sessionProposalPublisherSubject.eraseToAnyPublisher()
    }

    var sessionRequestPublisherSubject = PassthroughSubject<Request, Never>()
    public var sessionRequestPublisher: AnyPublisher<Request, Never> {
        sessionRequestPublisherSubject.eraseToAnyPublisher()
    }

    var socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    var sessionSettlePublisherSubject = PassthroughSubject<Session, Never>()
    public var sessionSettlePublisher: AnyPublisher<Session, Never> {
        sessionSettlePublisherSubject.eraseToAnyPublisher()
    }

    var sessionDeletePublisherSubject = PassthroughSubject<(String, Reason), Never>()
    public var sessionDeletePublisher: AnyPublisher<(String, Reason), Never> {
        sessionDeletePublisherSubject.eraseToAnyPublisher()
    }

    var sessionResponsePublisherSubject = PassthroughSubject<Response, Never>()
    public var sessionResponsePublisher: AnyPublisher<Response, Never> {
        sessionResponsePublisherSubject.eraseToAnyPublisher()
    }

    var sessionRejectionPublisherSubject = PassthroughSubject<(Session.Proposal, Reason), Never>()
    public var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        sessionRejectionPublisherSubject.eraseToAnyPublisher()
    }

    var sessionUpdatePublisherSubject = PassthroughSubject<(sessionTopic: String, namespaces: [String: SessionNamespace]), Never>()
    public var sessionUpdatePublisher: AnyPublisher<(sessionTopic: String, namespaces: [String: SessionNamespace]), Never> {
        sessionUpdatePublisherSubject.eraseToAnyPublisher()
    }

    var sessionEventPublisherSubject = PassthroughSubject<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never>()
    public var sessionEventPublisher: AnyPublisher<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never> {
        sessionEventPublisherSubject.eraseToAnyPublisher()
    }

    var sessionExtendPublisherSubject = PassthroughSubject<(sessionTopic: String, date: Date), Never>()
    public var sessionExtendPublisher: AnyPublisher<(sessionTopic: String, date: Date), Never> {
        sessionExtendPublisherSubject.eraseToAnyPublisher()
    }
}

extension Sign: SignClientDelegate {

    public func didReceive(sessionProposal: Session.Proposal) {
        sessionProposalPublisherSubject.send(sessionProposal)
    }

    public func didReceive(sessionRequest: Request) {
        sessionRequestPublisherSubject.send(sessionRequest)
    }

    public func didReceive(sessionResponse: Response) {
        sessionResponsePublisherSubject.send(sessionResponse)
    }

    public func didDelete(sessionTopic: String, reason: Reason) {
        sessionDeletePublisherSubject.send((sessionTopic, reason))
    }

    public func didUpdate(sessionTopic: String, namespaces: [String: SessionNamespace]) {
        sessionUpdatePublisherSubject.send((sessionTopic, namespaces))
    }

    public func didExtend(sessionTopic: String, to date: Date) {
        sessionExtendPublisherSubject.send((sessionTopic, date))
    }

    public func didSettle(session: Session) {
        sessionSettlePublisherSubject.send(session)
    }

    public func didReceive(event: Session.Event, sessionTopic: String, chainId: Blockchain?) {
        sessionEventPublisherSubject.send((event, sessionTopic, chainId))
    }

    public func didReject(proposal: Session.Proposal, reason: Reason) {
        sessionRejectionPublisherSubject.send((proposal, reason))
    }

    public func didChangeSocketConnectionStatus(_ status: SocketConnectionStatus) {
        socketConnectionStatusPublisherSubject.send(status)
    }
}

extension Sign {

    /// For the Proposer to propose a session to a responder.
    /// Function will create pending pairing sequence or propose a session on existing pairing. When responder client approves pairing, session is be proposed automatically by your client.
    /// - Parameter sessionPermissions: The session permissions the responder will be requested for.
    /// - Parameter topic: Optional parameter - use it if you already have an established pairing with peer client.
    /// - Returns: Pairing URI that should be shared with responder out of bound. Common way is to present it as a QR code. Pairing URI will be nil if you are going to establish a session on existing Pairing and `topic` function parameter was provided.
    public func connect(requiredNamespaces: [String: ProposalNamespace], topic: String? = nil) async throws -> String? {
        try await client.connect(requiredNamespaces: requiredNamespaces, topic: topic)
    }

    /// For responder to receive a session proposal from a proposer
    /// Responder should call this function in order to accept peer's pairing proposal and be able to subscribe for future session proposals.
    /// - Parameter uri: Pairing URI that is commonly presented as a QR code by a dapp.
    ///
    /// Should Error:
    /// - When URI is invalid format or missing params
    /// - When topic is already in use
    public func pair(uri: String) async throws {
        try await client.pair(uri: uri)
    }

    /// For the responder to approve a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal Public key received from peer client in a WalletConnect delegate function: `didReceive(sessionProposal: Session.Proposal)`
    ///   - accounts: A Set of accounts that the dapp will be allowed to request methods executions on.
    ///   - methods: A Set of methods that the dapp will be allowed to request.
    ///   - events: A Set of events
    public func approve(proposalId: String, namespaces: [String: SessionNamespace]) async throws {
        try await client.approve(proposalId: proposalId, namespaces: namespaces)
    }

    /// For the responder to reject a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal Public key received from peer client in a WalletConnect delegate.
    ///   - reason: Reason why the session proposal was rejected. Conforms to CAIP25.
    public func reject(proposalId: String, reason: RejectionReason) async throws {
        try await client.reject(proposalId: proposalId, reason: reason)
    }

    /// For the responder to update session methods
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - methods: Sets of methods that will replace existing ones.
    public func update(topic: String, namespaces: [String: SessionNamespace]) async throws {
        try await client.update(topic: topic, namespaces: namespaces)
    }

    /// For controller to update expiry of a session
    /// - Parameters:
    ///   - topic: Topic of the Session, it can be a pairing or a session topic.
    ///   - ttl: Time in seconds that a target session is expected to be extended for. Must be greater than current time to expire and than 7 days
    public func extend(topic: String) async throws {
        try await client.extend(topic: topic)
    }

    /// For the proposer to send JSON-RPC requests to responding peer.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    public func request(params: Request) async throws {
        try await client.request(params: params)
    }

    /// For the responder to respond on pending peer's session JSON-RPC Request
    /// - Parameters:
    ///   - topic: Topic of the session for which the request was received.
    ///   - response: Your JSON RPC response or an error.
    public func respond(topic: String, response: JsonRpcResult) async throws {
        try await client.respond(topic: topic, response: response)
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
        client.ping(topic: topic, completion: completion)
    }

    /// - Parameters:
    ///   - topic: Session topic
    ///   - params: Event Parameters
    ///   - completion: calls a handler upon completion
    public func emit(topic: String, event: Session.Event, chainId: Blockchain) async throws {
        try await client.emit(topic: topic, event: event, chainId: chainId)
    }

    /// - Parameters:
    ///   - topic: Session topic that you want to delete
    ///   - reason: Reason of session deletion
    public func disconnect(topic: String, reason: Reason) async throws {
        try await client.disconnect(topic: topic, reason: reason)
    }

    /// - Returns: All sessions
    public func getSessions() -> [Session] {
        client.getSessions()
    }

    /// - Returns: All settled pairings that are active
    public func getSettledPairings() -> [Pairing] {
        client.getSettledPairings()
    }

    /// - Returns: Pending requests received with wc_sessionRequest
    /// - Parameter topic: topic representing session for which you want to get pending requests. If nil, you will receive pending requests for all active sessions.
    public func getPendingRequests(topic: String? = nil) -> [Request] {
        client.getPendingRequests(topic: topic)
    }

    /// - Parameter id: id of a wc_sessionRequest jsonrpc request
    /// - Returns: json rpc record object for given id or nil if record for give id does not exits
    public func getSessionRequestRecord(id: Int64) -> WalletConnectUtils.JsonRpcRecord? {
        client.getSessionRequestRecord(id: id)
    }

    public func connect() throws {
        try relayClient.connect()
    }

    public func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        try relayClient.disconnect(closeCode: closeCode)
    }

#if DEBUG
    /// Delete all stored data sach as: pairings, sessions, keys
    ///
    /// - Note: Doesn't unsubscribe from topics
    public func cleanup() throws {
        try client.cleanup()
    }
#endif
}
