import Combine

public final class DeleteRequestSubscriber {
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
        subscribeDeleteRequest()
    }
    
    private func subscribeDeleteRequest() {
        networkingInteractor.requestSubscription(on: method)
            .sink { [unowned self]  (payload: RequestSubscriptionPayload<PairingDeleteParams>) in
                onResponse?(payload.topic)
                
                logger.debug("Responding for pairing delete")
                Task(priority: .high) {
                    try? await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: method)
                }
            }
            .store(in: &publishers)
    }
}
