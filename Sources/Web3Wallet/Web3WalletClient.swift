import Foundation
import Combine

/// Web3 Wallet Client
///
/// Cannot be instantiated outside of the SDK
///
/// Access via `Web3Wallet.instance`
public class Web3WalletClient {
    // MARK: - Public Properties
    
    /// Publisher that sends session proposal
    ///
    /// event is emited on responder client only
    public var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> {
        signClient.sessionProposalPublisher.eraseToAnyPublisher()
    }

    /// Publisher that sends session request
    ///
    /// In most cases event will be emited on wallet
    public var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        signClient.sessionRequestPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends authentication requests
    ///
    /// Wallet should subscribe on events in order to receive auth requests.
    public var authenticateRequestPublisher: AnyPublisher<(request: AuthenticationRequest, context: VerifyContext?), Never> {
        signClient.authenticateRequestPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends sessions on every sessions update
    ///
    /// Event will be emited on controller and non-controller clients.
    public var sessionsPublisher: AnyPublisher<[Session], Never> {
        signClient.sessionsPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends web socket connection status
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        signClient.socketConnectionStatusPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends session when one is settled
    ///
    /// Event is emited on proposer and responder client when both communicating peers have successfully established a session.
    public var sessionSettlePublisher: AnyPublisher<Session, Never> {
        signClient.sessionSettlePublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends deleted session topic
    ///
    /// Event can be emited on any type of the client.
    public var sessionDeletePublisher: AnyPublisher<(String, Reason), Never> {
        signClient.sessionDeletePublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends response for session request
    ///
    /// In most cases that event will be emited on dApp client.
    public var sessionResponsePublisher: AnyPublisher<Response, Never> {
        signClient.sessionResponsePublisher.eraseToAnyPublisher()
    }

    public var pairingDeletePublisher: AnyPublisher<(code: Int, message: String), Never> {
        pairingClient.pairingDeletePublisher
    }

    public var pairingStatePublisher: AnyPublisher<Bool, Never> {
        pairingClient.pairingStatePublisher
    }

    public var pairingExpirationPublisher: AnyPublisher<Pairing, Never> {
        return pairingClient.pairingExpirationPublisher
    }

    public var logsPublisher: AnyPublisher<Log, Never> {
        return signClient.logsPublisher
            .merge(with: pairingClient.logsPublisher)
            .eraseToAnyPublisher()
    }

    /// Publisher that sends session proposal expiration
    public var sessionProposalExpirationPublisher: AnyPublisher<Session.Proposal, Never> {
        return signClient.sessionProposalExpirationPublisher
    }

    public var pendingProposalsPublisher: AnyPublisher<[(proposal: Session.Proposal, context: VerifyContext?)], Never> {
        return signClient.pendingProposalsPublisher
    }

    public var requestExpirationPublisher: AnyPublisher<RPCID, Never> {
        return signClient.requestExpirationPublisher
    }

    // MARK: - Private Properties
    private let signClient: SignClientProtocol
    private let pairingClient: PairingClientProtocol
    private let pushClient: PushClientProtocol
    
    private var account: Account?

    init(
        signClient: SignClientProtocol,
        pairingClient: PairingClientProtocol,
        pushClient: PushClientProtocol
    ) {
        self.signClient = signClient
        self.pairingClient = pairingClient
        self.pushClient = pushClient
    }
    
    /// For a wallet to approve a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal id
    ///   - namespaces: namespaces for given session, needs to contain at least required namespaces proposed by dApp.
    public func approve(proposalId: String, namespaces: [String: SessionNamespace], sessionProperties: [String: String]? = nil) async throws -> Session {
        try await signClient.approve(proposalId: proposalId, namespaces: namespaces, sessionProperties: sessionProperties)
    }

    /// For the wallet to reject a session proposal.
    /// - Parameters:
    ///   - proposalId: Session Proposal id
    ///   - reason: Reason why the session proposal has been rejected. Conforms to CAIP25.
    public func rejectSession(proposalId: String, reason: RejectionReason) async throws {
        try await signClient.rejectSession(proposalId: proposalId, reason: reason)
    }

    /// For the wallet to update session namespaces
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be updated.
    ///   - namespaces: Dictionary of namespaces that will replace existing ones.
    public func update(topic: String, namespaces: [String: SessionNamespace]) async throws {
        try await signClient.update(topic: topic, namespaces: namespaces)
    }

    /// For wallet to extend a session to 7 days
    /// - Parameters:
    ///   - topic: Topic of the session that is intended to be extended.
    public func extend(topic: String) async throws {
        try await signClient.extend(topic: topic)
    }
    
    /// For the wallet to respond on pending dApp's JSON-RPC request
    /// - Parameters:
    ///   - topic: Topic of the session for which the request was received.
    ///   - requestId: RPC request ID
    ///   - response: Your JSON RPC response or an error.
    public func respond(topic: String, requestId: RPCID, response: RPCResult) async throws {
        try await signClient.respond(topic: topic, requestId: requestId, response: response)
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
        try await signClient.emit(topic: topic, event: event, chainId: chainId)
    }
    
    /// For wallet to receive a session proposal from a dApp
    /// Responder should call this function in order to accept peer's pairing and be able to subscribe for future session proposals.
    /// - Parameter uri: Pairing URI that is commonly presented as a QR code by a dapp.
    ///
    /// Should Error:
    /// - When URI has invalid format or missing params
    /// - When topic is already in use
    public func pair(uri: WalletConnectURI) async throws {
        try await pairingClient.pair(uri: uri)
    }

    @available(*, deprecated, message: "This method is deprecated. Pairing will disconnect automatically")
    public func disconnectPairing(topic: String) async {}
    
    /// For a wallet and a dApp to terminate a session
    ///
    /// Should Error:
    /// - When the session topic is not found
    /// - Parameters:
    ///   - topic: Session topic that you want to delete
    public func disconnect(topic: String) async throws {
        try await signClient.disconnect(topic: topic)
    }

    /// Query sessions
    /// - Returns: All sessions
    public func getSessions() -> [Session] {
        signClient.getSessions()
    }
    
    public func formatAuthMessage(payload: AuthPayload, account: Account) throws -> String {
        try signClient.formatAuthMessage(payload: payload, account: account)
    }

    //---------------------------------------AUTH------------------------------------
    /// For a wallet to respond on authentication request
    /// - Parameters:
    ///   - requestId: authentication request id
    ///   - auths: CACAO objects
    public func approveSessionAuthenticate(requestId: RPCID, auths: [AuthObject]) async throws -> Session? {
        try await signClient.approveSessionAuthenticate(requestId: requestId, auths: auths)
    }

    /// For wallet to reject authentication request
    /// - Parameter requestId: authentication request id
    public func rejectSession(requestId: RPCID) async throws {
        try await signClient.rejectSession(requestId: requestId)
    }


    /// Query pending authentication requests
    /// - Returns: Pending authentication requests
    public func getPendingAuthRequests() throws -> [(AuthenticationRequest, VerifyContext?)] {
        return try signClient.getPendingAuthRequests()
    }
    //---------------------------------------------------

    
    /// Query pending requests
    /// - Returns: Pending requests received from peer with `wc_sessionRequest` protocol method
    /// - Parameter topic: topic representing session for which you want to get pending requests. If nil, you will receive pending requests for all active sessions.
    public func getPendingRequests(topic: String? = nil) -> [(request: Request, context: VerifyContext?)] {
        signClient.getPendingRequests(topic: topic)
    }

    public func getPendingProposals(topic: String? = nil) -> [(proposal: Session.Proposal, context: VerifyContext?)] {
        signClient.getPendingProposals(topic: topic)
    }

    public func buildSignedAuthObject(authPayload: AuthPayload, signature: CacaoSignature, account: Account) throws -> AuthObject {
        try signClient.buildSignedAuthObject(authPayload: authPayload, signature: signature, account: account)
    }

    public func buildAuthPayload(payload: AuthPayload, supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> AuthPayload {
        try signClient.buildAuthPayload(payload: payload, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)
    }

    public func dispatchEnvelope(_ envelope: String) throws {
        try signClient.dispatchEnvelope(envelope)
    }

    public func register(deviceToken: Data, enableEncrypted: Bool = false) async throws {
        try await pushClient.register(deviceToken: deviceToken, enableEncrypted: enableEncrypted)
    }
    
    /// Delete all stored data such as: pairings, sessions, keys
    ///
    /// - Note: Will unsubscribe from all topics
    public func cleanup() async throws {
        try await signClient.cleanup()
    }
    
    public func getPairings() -> [Pairing] {
        return pairingClient.getPairings()
    }
}

#if DEBUG
extension Web3WalletClient {
    public func register(deviceToken: String, enableEncrypted: Bool = false) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }
}
#endif
