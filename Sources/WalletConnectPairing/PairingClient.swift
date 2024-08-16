import Foundation
import Combine

public class PairingClient: PairingRegisterer, PairingInteracting, PairingClientProtocol {
    public var pairingDeletePublisher: AnyPublisher<(code: Int, message: String), Never> {
        pairingDeleteRequestSubscriber.deletePublisherSubject.eraseToAnyPublisher()
    }

    public var pairingStatePublisher: AnyPublisher<Bool, Never> {
        return pairingStateProvider.pairingStatePublisher
    }

    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    public var pairingExpirationPublisher: AnyPublisher<Pairing, Never> {
        return expirationService.pairingExpirationPublisher
    }

    private let pairingStorage: WCPairingStorage
    private let walletPairService: WalletPairService
    private let appPairService: AppPairService
    private let logger: ConsoleLogging
    private let networkingInteractor: NetworkInteracting
    private let pairingRequestsSubscriber: PairingRequestsSubscriber
    private let pairingsProvider: PairingsProvider
    private let resubscribeService: PairingResubscribeService
    private let expirationService: ExpirationService
    private let pairingDeleteRequestSubscriber: PairingDeleteRequestSubscriber
    private let pairingStateProvider: PairingStateProvider

    private let cleanupService: PairingCleanupService

    public var logsPublisher: AnyPublisher<Log, Never> {
        return logger.logsPublisher
    }

    init(
        pairingStorage: WCPairingStorage,
        appPairService: AppPairService,
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        walletPairService: WalletPairService,
        pairingDeleteRequestSubscriber: PairingDeleteRequestSubscriber,
        resubscribeService: PairingResubscribeService,
        expirationService: ExpirationService,
        pairingRequestsSubscriber: PairingRequestsSubscriber,
        cleanupService: PairingCleanupService,
        socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>,
        pairingsProvider: PairingsProvider,
        pairingStateProvider: PairingStateProvider
    ) {
        self.pairingStorage = pairingStorage
        self.appPairService = appPairService
        self.walletPairService = walletPairService
        self.networkingInteractor = networkingInteractor
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.logger = logger
        self.pairingDeleteRequestSubscriber = pairingDeleteRequestSubscriber
        self.resubscribeService = resubscribeService
        self.expirationService = expirationService
        self.cleanupService = cleanupService
        self.pairingRequestsSubscriber = pairingRequestsSubscriber
        self.pairingsProvider = pairingsProvider
        self.pairingStateProvider = pairingStateProvider
        setUpExpiration()
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

    public func create(methods: [String]? = nil)  async throws -> WalletConnectURI {
        return try await appPairService.create(supportedMethods: methods)
    }

    public func setReceived(pairingTopic: String) {
        guard var pairing = pairingStorage.getPairing(forTopic: pairingTopic) else {
            return logger.error("Pairing not found for topic: \(pairingTopic)")
        }

        pairing.receivedRequest()
        pairingStorage.setPairing(pairing)
    }

    public func getPairings() -> [Pairing] {
        pairingsProvider.getPairings()
    }

    public func getPairing(for topic: String) throws -> Pairing {
        try pairingsProvider.getPairing(for: topic)
    }

    @available(*, deprecated, message: "This method is deprecated. Pairing will disconnect automatically")
    public func disconnect(topic: String) async {}

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
