import Combine
import WalletConnectUtils
import WalletConnectNetworking

class PingResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()

    var onResponse: ((String)->())?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        subscribePingResponses()
    }

    private func subscribePingResponses() {
        networkingInteractor.responseSubscription(on: PairingProtocolMethod.ping)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<PairingPingParams, Bool>) in
                onResponse?(payload.topic)
            }
            .store(in: &publishers)
    }
}
