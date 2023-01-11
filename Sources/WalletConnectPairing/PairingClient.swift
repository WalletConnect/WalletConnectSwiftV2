import Foundation
import Combine

public class PairingClient: PairingRegisterer, PairingInteracting, PairingClientProtocol {
    public var pingResponsePublisher: AnyPublisher<(String), Never> {
        pingResponsePublisherSubject.eraseToAnyPublisher()
    }
    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    private let walletPairService: WalletPairService
    private let appPairService: AppPairService
    private let appPairActivateService: AppPairActivationService
    private var pingResponsePublisherSubject = PassthroughSubject<String, Never>()
    private let logger: ConsoleLogging
    private let pingService: PairingPingService
    private let networkingInteractor: NetworkInteracting
    private let pairingRequestsSubscriber: PairingRequestsSubscriber
    private let pairingsProvider: PairingsProvider
    private let deletePairingService: DeletePairingService
    private let resubscribeService: PairingResubscribeService
    private let expirationService: ExpirationService

    private let cleanupService: PairingCleanupService

    init(appPairService: AppPairService,
         networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         walletPairService: WalletPairService,
         deletePairingService: DeletePairingService,
         resubscribeService: PairingResubscribeService,
         expirationService: ExpirationService,
         pairingRequestsSubscriber: PairingRequestsSubscriber,
         appPairActivateService: AppPairActivationService,
         cleanupService: PairingCleanupService,
         pingService: PairingPingService,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>,
         pairingsProvider: PairingsProvider
    ) {
        self.appPairService = appPairService
        self.walletPairService = walletPairService
        self.networkingInteractor = networkingInteractor
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.logger = logger
        self.deletePairingService = deletePairingService
        self.appPairActivateService = appPairActivateService
        self.resubscribeService = resubscribeService
        self.expirationService = expirationService
        self.cleanupService = cleanupService
        self.pingService = pingService
        self.pairingRequestsSubscriber = pairingRequestsSubscriber
        self.pairingsProvider = pairingsProvider
        setUpPublishers()
        setUpExpiration()
    }

    private func setUpPublishers() {
        pingService.onResponse = { [unowned self] topic in
            pingResponsePublisherSubject.send(topic)
        }
    }

    private func setUpExpiration() {
        expirationService.setupExpirationHandling()
    }

    /// For wallet to establish a pairing
    /// Wallet should call this function in order to accept peer's pairing proposal and be able to subscribe for future requests.
    /// - Parameter uri: Pairing URI that is commonly presented as a QR code by a dapp or delivered with universal linking.
    ///
    /// Throws Error:
    /// - When URI is invalid format or missing params
    /// - When topic is already in use
    public func pair(uri: WalletConnectURI) async throws {
        try await walletPairService.pair(uri)
    }

    public func create()  async throws -> WalletConnectURI {
        return try await appPairService.create()
    }

    public func activate(pairingTopic: String, peerMetadata: AppMetadata?) {
        appPairActivateService.activate(for: pairingTopic, peerMetadata: peerMetadata)
    }

    public func getPairings() -> [Pairing] {
        pairingsProvider.getPairings()
    }

    public func getPairing(for topic: String) throws -> Pairing {
        try pairingsProvider.getPairing(for: topic)
    }

    public func ping(topic: String) async throws {
        try await pingService.ping(topic: topic)
    }

    public func disconnect(topic: String) async throws {
        try await deletePairingService.delete(topic: topic)
    }

    public func validatePairingExistance(_ topic: String) throws {
        _ = try pairingsProvider.getPairing(for: topic)
    }

    public func register<RequestParams>(method: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> {
        logger.debug("Pairing Client - registering for \(method.method)")
        return pairingRequestsSubscriber.subscribeForRequest(method)
    }

#if DEBUG
    /// Delete all stored data such as: pairings, keys
    ///
    /// - Note: Doesn't unsubscribe from topics
    public func cleanup() throws {
        try cleanupService.cleanup()
    }
#endif
}
