import Foundation
import WalletConnectUtils
import WalletConnectRelay
import WalletConnectNetworking
import Combine

public class PairingClient {
    private let walletPairService: WalletPairService
    private let appPairService: AppPairService
    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    let logger: ConsoleLogging
    private let networkingInteractor: NetworkInteracting
    private let pairingRequestsSubscriber: PairingRequestsSubscriber

    init(appPairService: AppPairService,
         networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         walletPairService: WalletPairService,
         pairingRequestsSubscriber: PairingRequestsSubscriber,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    ) {
        self.appPairService = appPairService
        self.walletPairService = walletPairService
        self.networkingInteractor = networkingInteractor
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.logger = logger
        self.pairingRequestsSubscriber = pairingRequestsSubscriber
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

    public func configureProtocols(with paringables: [Pairingable]) {
        pairingRequestsSubscriber.setPairingables(paringables)
    }
}

