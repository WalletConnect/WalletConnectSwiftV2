import Foundation
import WalletConnectUtils

class PairingClient {
    private let walletPairService: WalletPairService
    private let appPairService: AppPairService


    init(appPairService: AppPairService,
         walletPairService: WalletPairService
    ) {
        self.appPairService = appPairService
        self.walletPairService = walletPairService
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

    public func addSubscriber()

}
