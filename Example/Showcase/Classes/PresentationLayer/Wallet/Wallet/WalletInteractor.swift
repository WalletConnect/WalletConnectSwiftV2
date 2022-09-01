import Combine
import Auth

final class WalletInteractor {

    func pair(uri: WalletConnectURI) async throws {
        try await Auth.instance.pair(uri: uri)
    }

    var requestPublisher: AnyPublisher<AuthRequest, Never> {
        return Auth.instance.authRequestPublisher
    }
}
