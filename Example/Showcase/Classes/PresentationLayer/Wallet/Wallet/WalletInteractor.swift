import Combine
import Auth

final class WalletInteractor {

    func pair(uri: String) async throws {
        try await Auth.instance.pair(uri: uri)
    }

    var requestPublisher: AnyPublisher<AuthRequest, Never> {
        return Auth.instance.authRequestPublisher
    }
}
