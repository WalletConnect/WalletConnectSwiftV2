import Combine

public class PingResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let method: ProtocolMethod
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()

    public var onResponse: ((String)->Void)?

    public init(networkingInteractor: NetworkInteracting,
         method: ProtocolMethod,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.method = method
        self.logger = logger
        subscribePingResponses()
    }

    private func subscribePingResponses() {
        networkingInteractor.responseSubscription(on: method)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<PairingPingParams, Bool>) in
                onResponse?(payload.topic)

                Task(priority: .high) {
                    try await networkingInteractor.respondSuccess(
                        topic: payload.topic,
                        requestId: payload.id,
                        protocolMethod: method
                    )
                }
            }
            .store(in: &publishers)
    }
}
