import Foundation
import Combine
import WalletConnectUtils
import WalletConnectPairing
import WalletConnectRelay

/// WalletConnect Auth Client
///
/// Cannot be instantiated outside of the SDK
///
/// Access via `Auth.instance`
public class AuthClient {
    enum Errors: Error {
        case pairingUriWrongApiParam
        case unknownWalletAddress
        case noPairingMatchingTopic
    }

    // MARK: - Public Properties

    /// Publisher that sends authentication requests
    ///
    /// Wallet should subscribe on events in order to receive auth requests.
    public var authRequestPublisher: AnyPublisher<AuthRequest, Never> {
        authRequestPublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends authentication responses
    ///
    /// App should subscribe for events in order to receive CACAO object with a signature matching authentication request.
    ///
    /// Emited result may be an error.
    public var authResponsePublisher: AnyPublisher<(id: RPCID, result: Result<Cacao, AuthError>), Never> {
        authResponsePublisherSubject.eraseToAnyPublisher()
    }

    public var pingResponsePublisher: AnyPublisher<(String), Never> {
        pingResponsePublisherSubject.eraseToAnyPublisher()
    }

    /// Publisher that sends web socket connection status
    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    /// An object that loggs SDK's errors and info messages
    public let logger: ConsoleLogging

    // MARK: - Private Properties

    private var authResponsePublisherSubject = PassthroughSubject<(id: RPCID, result: Result<Cacao, AuthError>), Never>()
    private var authRequestPublisherSubject = PassthroughSubject<AuthRequest, Never>()
    private var pingResponsePublisherSubject = PassthroughSubject<String, Never>()
    private let appPairService: AppPairService
    private let appRequestService: AppRequestService
    private let deletePairingService: DeletePairingService
    private let appRespondSubscriber: AppRespondSubscriber
    private let walletPairService: WalletPairService
    private let walletRequestSubscriber: WalletRequestSubscriber
    private let walletRespondService: WalletRespondService
    private let cleanupService: CleanupService
    private let pairingStorage: WCPairingStorage
    private let pendingRequestsProvider: PendingRequestsProvider
    private let pingService: PairingPingService
    private var account: Account?

    init(appPairService: AppPairService,
         appRequestService: AppRequestService,
         appRespondSubscriber: AppRespondSubscriber,
         walletPairService: WalletPairService,
         walletRequestSubscriber: WalletRequestSubscriber,
         walletRespondService: WalletRespondService,
         deletePairingService: DeletePairingService,
         account: Account?,
         pendingRequestsProvider: PendingRequestsProvider,
         cleanupService: CleanupService,
         logger: ConsoleLogging,
         pairingStorage: WCPairingStorage,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>,
         pingService: PairingPingService
    ) {
        self.appPairService = appPairService
        self.appRequestService = appRequestService
        self.walletPairService = walletPairService
        self.walletRequestSubscriber = walletRequestSubscriber
        self.walletRespondService = walletRespondService
        self.appRespondSubscriber = appRespondSubscriber
        self.account = account
        self.pendingRequestsProvider = pendingRequestsProvider
        self.cleanupService = cleanupService
        self.logger = logger
        self.pairingStorage = pairingStorage
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.deletePairingService = deletePairingService
        self.pingService = pingService
        setUpPublishers()
    }

    /// For wallet to establish a pairing and receive an authentication request
    /// Wallet should call this function in order to accept peer's pairing proposal and be able to subscribe for future authentication request.
    /// - Parameter uri: Pairing URI that is commonly presented as a QR code by a dapp or delivered with universal linking.
    ///
    /// Throws Error:
    /// - When URI is invalid format or missing params
    /// - When topic is already in use
    public func pair(uri: WalletConnectURI) async throws {
        guard uri.api == .auth else {
            throw Errors.pairingUriWrongApiParam
        }
        try await walletPairService.pair(uri)
    }

    /// For a dapp to send an authentication request to a wallet
    /// - Parameter params: Set of parameters required to request authentication
    ///
    /// - Returns: Pairing URI that should be shared with wallet out of bound. Common way is to present it as a QR code.
    public func request(_ params: RequestParams) async throws -> WalletConnectURI {
        logger.debug("Requesting Authentication")
        let uri = try await appPairService.create()
        try await appRequestService.request(params: params, topic: uri.topic)
        return uri
    }

    /// For a dapp to send an authentication request to a wallet
    /// - Parameter params: Set of parameters required to request authentication
    /// - Parameter topic: Pairing topic that wallet already subscribes for
    public func request(_ params: RequestParams, topic: String) async throws {
        logger.debug("Requesting Authentication on existing pairing")
        guard pairingStorage.hasPairing(forTopic: topic) else {
            throw Errors.noPairingMatchingTopic
        }
        try await appRequestService.request(params: params, topic: topic)
    }

    /// For a wallet to respond on authentication request
    /// - Parameters:
    ///   - requestId: authentication request id
    ///   - signature: CACAO signature of requested message
    public func respond(requestId: RPCID, signature: CacaoSignature) async throws {
        guard let account = account else { throw Errors.unknownWalletAddress }
        try await walletRespondService.respond(requestId: requestId, signature: signature, account: account)
    }

    /// For wallet to reject authentication request
    /// - Parameter requestId: authentication request id
    public func reject(requestId: RPCID) async throws {
        try await walletRespondService.respondError(requestId: requestId)
    }

    public func disconnect(topic: String) async throws {
        try await deletePairingService.delete(topic: topic)
    }

    public func ping(topic: String) async throws {
        try await pingService.ping(topic: topic)
    }

    /// Query pending authentication requests
    /// - Returns: Pending authentication requests
    public func getPendingRequests() throws -> [AuthRequest] {
        guard let account = account else { throw Errors.unknownWalletAddress }
        return try pendingRequestsProvider.getPendingRequests(account: account)
    }

#if DEBUG
    /// Delete all stored data such as: pairings, keys
    ///
    /// - Note: Doesn't unsubscribe from topics
    public func cleanup() throws {
        try cleanupService.cleanup()
    }
#endif

    private func setUpPublishers() {
        appRespondSubscriber.onResponse = { [unowned self] (id, result) in
            authResponsePublisherSubject.send((id, result))
        }

        walletRequestSubscriber.onRequest = { [unowned self] request in
            authRequestPublisherSubject.send(request)
        }
    }
}
