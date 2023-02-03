import Foundation
import Combine

/// WalletConnect Auth Client
///
/// Cannot be instantiated outside of the SDK
///
/// Access via `Auth.instance`
public class AuthClient: AuthClientProtocol {

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

    /// Publisher that sends web socket connection status
    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    /// An object that loggs SDK's errors and info messages
    public let logger: ConsoleLogging

    // MARK: - Private Properties

    private let pairingRegisterer: PairingRegisterer

    private var authResponsePublisherSubject = PassthroughSubject<(id: RPCID, result: Result<Cacao, AuthError>), Never>()
    private var authRequestPublisherSubject = PassthroughSubject<AuthRequest, Never>()
    private let appRequestService: AppRequestService
    private let appRespondSubscriber: AppRespondSubscriber
    private let walletRequestSubscriber: WalletRequestSubscriber
    private let walletRespondService: WalletRespondService
    private let pendingRequestsProvider: PendingRequestsProvider

    init(appRequestService: AppRequestService,
         appRespondSubscriber: AppRespondSubscriber,
         walletRequestSubscriber: WalletRequestSubscriber,
         walletRespondService: WalletRespondService,
         pendingRequestsProvider: PendingRequestsProvider,
         logger: ConsoleLogging,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>,
         pairingRegisterer: PairingRegisterer
    ) {
        self.appRequestService = appRequestService
        self.walletRequestSubscriber = walletRequestSubscriber
        self.walletRespondService = walletRespondService
        self.appRespondSubscriber = appRespondSubscriber
        self.pendingRequestsProvider = pendingRequestsProvider
        self.logger = logger
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.pairingRegisterer = pairingRegisterer
        setUpPublishers()
    }

    /// For a dapp to send an authentication request to a wallet
    /// - Parameter params: Set of parameters required to request authentication
    /// - Parameter topic: Pairing topic that wallet already subscribes for
    public func request(_ params: RequestParams, topic: String) async throws {
        logger.debug("Requesting Authentication on existing pairing")
        try pairingRegisterer.validatePairingExistance(topic)
        try await appRequestService.request(params: params, topic: topic)
    }

    /// For a wallet to respond on authentication request
    /// - Parameters:
    ///   - requestId: authentication request id
    ///   - signature: CACAO signature of requested message
    public func respond(requestId: RPCID, signature: CacaoSignature, from account: Account) async throws {
        try await walletRespondService.respond(requestId: requestId, signature: signature, account: account)
    }

    /// For wallet to reject authentication request
    /// - Parameter requestId: authentication request id
    public func reject(requestId: RPCID) async throws {
        try await walletRespondService.respondError(requestId: requestId)
    }

    /// Query pending authentication requests
    /// - Returns: Pending authentication requests
    public func getPendingRequests() throws -> [AuthRequest] {
        return try pendingRequestsProvider.getPendingRequests()
    }

    public func formatMessage(payload: AuthPayload, address: String) throws -> String {
        return try SIWECacaoFormatter().formatMessage(from: payload.cacaoPayload(address: address))
    }

    private func setUpPublishers() {
        appRespondSubscriber.onResponse = { [unowned self] (id, result) in
            authResponsePublisherSubject.send((id, result))
        }

        walletRequestSubscriber.onRequest = { [unowned self] request in
            authRequestPublisherSubject.send(request)
        }
    }
}
