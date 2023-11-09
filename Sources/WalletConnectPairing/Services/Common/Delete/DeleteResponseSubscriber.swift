import Combine

public final class DeleteResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let method: ProtocolMethod
    private let logger: ConsoleLogging
    
    public var onResponse: ((String) -> Void)?
    
    private var publishers = [AnyCancellable]()
    
    public init(
        networkingInteractor: NetworkInteracting,
        method: ProtocolMethod,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.method = method
        self.logger = logger
        subscribeDeleteResponse()
    }
    
    private func subscribeDeleteResponse() {
        networkingInteractor.responseSubscription(on: method)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<PairingDeleteParams, Bool>) in
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
