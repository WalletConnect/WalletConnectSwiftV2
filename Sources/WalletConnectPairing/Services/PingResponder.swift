import Combine
import WalletConnectUtils
import WalletConnectNetworking

class PingResponder {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        subscribePingRequests()
    }

    private func subscribePingRequests() {
        networkingInteractor.requestSubscription(on: PairingProtocolMethod.ping)
            .sink { [unowned self]  (payload: RequestSubscriptionPayload<PairingPingParams>) in
                logger.debug("Responding for pairing ping")
                Task(priority: .high) {
                    try? await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: PairingProtocolMethod.ping.responseTag)
                }
            }
            .store(in: &publishers)
    }
}
