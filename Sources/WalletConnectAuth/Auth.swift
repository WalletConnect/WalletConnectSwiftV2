
import Foundation
import WalletConnectUtils
import WalletConnectRelay
import Combine

public class Auth {
    static let instance = Auth()
    private let client: AuthClient
    private static var config: Config?
    
    private init() {
        guard let config = Auth.config else {
            fatalError("Error - you must configure before accessing Auth.instance")
        }
        let relayClient = RelayClient(relayHost: "relay.walletconnect.com", projectId: config.projectId, socketConnectionType: config.socketConnectionType)
        client = AuthClient(metadata: config.metadata, relayClient: relayClient)
    }
    
    static func configure(_ config: Config) {
        Auth.config = config
    }
    
    var connectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    var connectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        connectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    
    var sessionProposalPublisherSubject = PassthroughSubject<Session.Proposal, Never>()
    var sessionProposalPublisher: AnyPublisher<Session.Proposal, Never> {
        sessionProposalPublisherSubject.eraseToAnyPublisher()
    }
    
    var sessionSettlePublisherSubject = PassthroughSubject<Session, Never>()
    var sessionSettlePublisher: AnyPublisher<Session, Never> {
        sessionSettlePublisherSubject.eraseToAnyPublisher()
    }
    
    var sessionDeletePublisherSubject = PassthroughSubject<(String, Reason), Never>()
    var sessionDeletePublisher: AnyPublisher<(String, Reason), Never> {
        sessionDeletePublisherSubject.eraseToAnyPublisher()
    }
    
    var sessionResponsePublisherSubject = PassthroughSubject<Response, Never>()
    var sessionResponsePublisher: AnyPublisher<Response, Never> {
        sessionResponsePublisherSubject.eraseToAnyPublisher()
    }
    
    var sessionRejectionPublisherSubject = PassthroughSubject<(Session.Proposal, Reason), Never>()
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        sessionRejectionPublisherSubject.eraseToAnyPublisher()
    }
    
    var sessionUpdatePublisherSubject = PassthroughSubject<(String, [String : SessionNamespace]), Never>()
    var sessionUpdatePublisher: AnyPublisher<(String, [String : SessionNamespace]), Never> {
        sessionUpdatePublisherSubject.eraseToAnyPublisher()
    }
    
}

extension Auth: AuthClientDelegate {
    public func didUpdate(sessionTopic: String, namespaces: [String : SessionNamespace]) {
        sessionUpdatePublisherSubject.send((sessionTopic, namespaces))
    }
    
    public func didDelete(sessionTopic: String, reason: Reason) {
        sessionDeletePublisherSubject.send((sessionTopic, reason))
    }
    
    public func didSettle(session: Session) {
        sessionSettlePublisherSubject.send(session)
    }
    
    public func didConnect() {
        
    }
    
    
}

extension Auth {
    
    /// For the Proposer to propose a session to a responder.
    /// Function will create pending pairing sequence or propose a session on existing pairing. When responder client approves pairing, session is be proposed automatically by your client.
    /// - Parameter sessionPermissions: The session permissions the responder will be requested for.
    /// - Parameter topic: Optional parameter - use it if you already have an established pairing with peer client.
    /// - Returns: Pairing URI that should be shared with responder out of bound. Common way is to present it as a QR code. Pairing URI will be nil if you are going to establish a session on existing Pairing and `topic` function parameter was provided.
    public func connect(requiredNamespaces: [String : ProposalNamespace], topic: String? = nil) async throws -> String? {
        try await client.connect(requiredNamespaces: requiredNamespaces)
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
    ///   - proposal: Session Proposal received from peer client in a WalletConnect delegate function: `didReceive(sessionProposal: Session.Proposal)`
    ///   - accounts: A Set of accounts that the dapp will be allowed to request methods executions on.
    ///   - methods: A Set of methods that the dapp will be allowed to request.
    ///   - events: A Set of events
    public func approve(proposalId: String, namespaces: [String : SessionNamespace]) throws {
        try client.approve(proposalId: proposalId, namespaces: namespaces)
    }

    /// For the responder to reject a session proposal.
    /// - Parameters:
    ///   - proposal: Session Proposal received from peer client in a WalletConnect delegate.
    ///   - reason: Reason why the session proposal was rejected. Conforms to CAIP25.
    public func reject(proposal: Session.Proposal, reason: RejectionReason) {
        client.reject(proposal: proposal, reason: reason)
    }

    /// For the responder to update session methods
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - methods: Sets of methods that will replace existing ones.
    public func update(topic: String, namespaces: [String : SessionNamespace]) async throws {
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
    public func respond(topic: String, response: JsonRpcResult) {
        client.respond(topic: topic, response: response)
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

    /// - Returns: All settled sessions that are active
    public func getSettledSessions() -> [Session] {
        client.getSettledSessions()
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
}
