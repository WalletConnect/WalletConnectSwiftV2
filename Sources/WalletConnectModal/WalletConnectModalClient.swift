import Combine

// Web3 Modal Client
///
/// Cannot be instantiated outside of the SDK
///
/// Access via `WalletConnectModal.instance`
public class WalletConnectModalClient {
    // MARK: - Public Properties
    
    /// Publisher that sends sessions on every sessions update
    ///
    /// Event will be emited on controller and non-controller clients.
    public var sessionsPublisher: AnyPublisher<[Session], Never> {
        signClient.sessionsPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends session when one is settled
    ///
    /// Event is emited on proposer and responder client when both communicating peers have successfully established a session.
    public var sessionSettlePublisher: AnyPublisher<Session, Never> {
        signClient.sessionSettlePublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends session proposal that has been rejected
    ///
    /// Event will be emited on dApp client only.
    public var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        signClient.sessionRejectionPublisher.eraseToAnyPublisher()
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
    
    /// Publisher that sends web socket connection status
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        signClient.socketConnectionStatusPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties

    private let signClient: SignClient
    private let pairingClient: PairingClientProtocol & PairingInteracting & PairingRegisterer
    
    init(
        signClient: SignClient,
        pairingClient: PairingClientProtocol & PairingInteracting & PairingRegisterer
    ) {
        self.signClient = signClient
        self.pairingClient = pairingClient
    }
    
    /// For creating new pairing
    public func createPairing() async throws -> WalletConnectURI {
        try await pairingClient.create()
    }
    
    /// For proposing a session to a wallet.
    /// Function will propose a session on existing pairing or create new one if not specified
    /// Namespaces from WalletConnectModal.config will be used
    public func connect() async throws -> WalletConnectURI {
            let pairingURI = try await signClient.connect(
                requiredNamespaces: WalletConnectModal.config.sessionParams.requiredNamespaces,
                optionalNamespaces: WalletConnectModal.config.sessionParams.optionalNamespaces,
                sessionProperties: WalletConnectModal.config.sessionParams.sessionProperties
            )
            return pairingURI
        }

    
    /// For sending JSON-RPC requests to wallet.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    public func request(params: Request) async throws {
        try await signClient.request(params: params)
    }
    
    /// For a terminating a session
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
    
    /// Query pairings
    /// - Returns: All pairings
    public func getPairings() -> [Pairing] {
        pairingClient.getPairings()
    }
    
    /// Delete all stored data such as: pairings, sessions, keys
    ///
    /// - Note: Will unsubscribe from all topics
    public func cleanup() async throws {
        try await signClient.cleanup()
    }
}
