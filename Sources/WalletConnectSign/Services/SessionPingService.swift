import Foundation
import WalletConnectPairing
import WalletConnectUtils
import WalletConnectNetworking

class SessionPingService {
    private let sessionStorage: WCSessionStorage
    private let pingRequester: PingRequester
    private let pingResponder: PingResponder
    private let pingResponseSubscriber: PingResponseSubscriber

    var onResponse: ((String)->())? {
        get {
            return pingResponseSubscriber.onResponse
        }
        set {
            pingResponseSubscriber.onResponse = newValue
        }
    }

    init(
        sessionStorage: WCSessionStorage,
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging) {
            self.sessionStorage = sessionStorage
            self.pingRequester = PingRequester(networkingInteractor: networkingInteractor, method: SignProtocolMethod.sessionPing)
            self.pingResponder = PingResponder(networkingInteractor: networkingInteractor, method: SignProtocolMethod.sessionPing, logger: logger)
            self.pingResponseSubscriber = PingResponseSubscriber(networkingInteractor: networkingInteractor, method: SignProtocolMethod.sessionPing, logger: logger)
        }

    func ping(topic: String) async throws {
        guard sessionStorage.hasSession(forTopic: topic) else { return }
        try await pingRequester.ping(topic: topic)
    }
}
