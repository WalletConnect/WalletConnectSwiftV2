import Combine

public final class PairingDeleteRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let pairingStorage: WCPairingStorage
    private let kms: KeyManagementServiceProtocol
    let deletePublisherSubject = PassthroughSubject<(code: Int, message: String), Never>()

    private var publishers = [AnyCancellable]()

    public init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        pairingStorage: WCPairingStorage,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
        self.logger = logger
        subscribeDeleteRequest()
    }

    private func subscribeDeleteRequest() {
        let method = PairingProtocolMethod.delete
        networkingInteractor.requestSubscription(on: method)
            .sink { [unowned self]  (payload: RequestSubscriptionPayload<PairingDeleteParams>) in

                let topic = payload.topic
                logger.debug("Received pairing delete request")
                pairingStorage.delete(topic: topic)
                kms.deleteSymmetricKey(for: topic)
                networkingInteractor.unsubscribe(topic: topic)

                deletePublisherSubject.send((code: payload.request.code, message: payload.request.message))
                Task(priority: .high) {
                    try? await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: method)
                }
            }
            .store(in: &publishers)
    }
}
