import Foundation
import WalletConnectUtils
import WalletConnectRelay
import Combine

public class PairingClient {
    private let walletPairService: WalletPairService
    private let appPairService: AppPairService
    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    let logger: ConsoleLogging
    init(appPairService: AppPairService,
         logger: ConsoleLogging,
         walletPairService: WalletPairService,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    ) {
        self.appPairService = appPairService
        self.walletPairService = walletPairService
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.logger = logger
    }
    /// For wallet to establish a pairing and receive an authentication request
    /// Wallet should call this function in order to accept peer's pairing proposal and be able to subscribe for future authentication request.
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

    public func configure(with paringables: [Paringable]) {
        var p = paringables.first!

        p.pairingRequestSubscriber = PairingRequestSubscriber(networkingInteractor: walletPairService.networkingInteractor, logger: logger, kms: walletPairService.kms, protocolMethod: p.protocolMethod)


        p.pairingRequester = PairingRequester(networkingInteractor: walletPairService.networkingInteractor, kms: walletPairService.kms, logger: logger, protocolMethod: p.protocolMethod)
    }

    

}
