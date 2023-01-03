import Combine
import Web3Wallet

final class ConnectionDetailsInteractor {
    func pair(uri: WalletConnectURI) async throws {
        try await Web3Wallet.instance.pair(uri: uri)
    }

    var requestPublisher: AnyPublisher<AuthRequest, Never> {
        return Web3Wallet.instance.authRequestPublisher
    }
}
