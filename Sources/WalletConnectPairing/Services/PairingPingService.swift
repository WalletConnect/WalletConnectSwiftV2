import WalletConnectUtils
import Foundation
import WalletConnectNetworking

public class PairingPingService {
    private let pingRequester: PingRequester
    private let pingResponder: PingResponder
    private let pingResponseSubscriber: PingResponseSubscriber

    var onResponse: ((String)->())? {
        return pingResponseSubscriber.onResponse
    }

    public init(
        pairingStorage: WCPairingStorage,
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging) {
            pingRequester = PingRequester(pairingStorage: pairingStorage, networkingInteractor: networkingInteractor)
            pingResponder = PingResponder(networkingInteractor: networkingInteractor, logger: logger)
            pingResponseSubscriber = PingResponseSubscriber(networkingInteractor: networkingInteractor, logger: logger)
        }

    public func ping(topic: String) async throws {
        try await pingRequester.ping(topic: topic)
    }

}
