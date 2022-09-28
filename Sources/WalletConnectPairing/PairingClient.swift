import Foundation
import WalletConnectUtils
import WalletConnectRelay
import WalletConnectNetworking
import Combine
import JSONRPC

public class PairingClient: PairingRegisterer {
    private let walletPairService: WalletPairService
    private let appPairService: AppPairService
    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    private let logger: ConsoleLogging
    private let networkingInteractor: NetworkInteracting
    private let pairingRequestsSubscriber: PairingRequestsSubscriber
    private let pairingsProvider: PairingsProvider
    private let cleanupService: CleanupService

    init(appPairService: AppPairService,
         networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         walletPairService: WalletPairService,
         pairingRequestsSubscriber: PairingRequestsSubscriber,
         cleanupService: CleanupService,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>,
         pairingsProvider: PairingsProvider
    ) {
        self.appPairService = appPairService
        self.walletPairService = walletPairService
        self.networkingInteractor = networkingInteractor
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.logger = logger
        self.cleanupService = cleanupService
        self.pairingRequestsSubscriber = pairingRequestsSubscriber
        self.pairingsProvider = pairingsProvider
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

    public func activate(_ topic: String) {

    }

    public func updateExpiry(_ topic: String) {

    }

    public func updateMetadata(_ topic: String, metadata: AppMetadata) {

    }

    public func getPairings() -> [Pairing] {
        pairingsProvider.getPairings()
    }

    public func ping(_ topic: String) {

    }

    public func disconnect(topic: String) async throws {

    }

    public func register(method: ProtocolMethod) -> AnyPublisher<(topic: String, request: RPCRequest), Never> {
        pairingRequestsSubscriber.subscribeForRequest(method)
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

