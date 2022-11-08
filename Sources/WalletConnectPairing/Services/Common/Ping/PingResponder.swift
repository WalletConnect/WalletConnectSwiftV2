import Combine

public class PingResponder {
    private let networkingInteractor: NetworkInteracting
    private let method: ProtocolMethod
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()

    public init(networkingInteractor: NetworkInteracting,
         method: ProtocolMethod,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.method = method
        self.logger = logger
        subscribePingRequests()
    }

    private func subscribePingRequests() {
        networkingInteractor.requestSubscription(on: method)
            .sink { [unowned self]  (payload: RequestSubscriptionPayload<PairingPingParams>) in
                logger.debug("Responding for pairing ping")
                Task(priority: .high) {
                    try? await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: method)
                }
            }
            .store(in: &publishers)
    }
}
