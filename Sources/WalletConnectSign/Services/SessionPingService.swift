import Foundation
import WalletConnectPairing
import WalletConnectUtils
import WalletConnectNetworking

class SessionPingService {
    private let sessionStorage: WCSessionStorage
    private let pingRequester: PingRequester
    private let pingResponder: PingResponder
    private let pingResponseSubscriber: PingResponseSubscriber

    var onResponse: ((String)->Void)? {
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
            let protocolMethod = SessionPingProtocolMethod()
            self.sessionStorage = sessionStorage
            self.pingRequester = PingRequester(networkingInteractor: networkingInteractor, method: protocolMethod)
            self.pingResponder = PingResponder(networkingInteractor: networkingInteractor, method: protocolMethod, logger: logger)
            self.pingResponseSubscriber = PingResponseSubscriber(networkingInteractor: networkingInteractor, method: protocolMethod, logger: logger)
        }

    func ping(topic: String) async throws {
        guard sessionStorage.hasSession(forTopic: topic) else { return }
        try await pingRequester.ping(topic: topic)
    }
}
