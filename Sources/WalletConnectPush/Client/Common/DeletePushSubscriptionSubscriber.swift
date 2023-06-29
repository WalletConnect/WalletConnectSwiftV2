import Foundation
import Combine

class DeletePushSubscriptionSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let pushStorage: PushStorage

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         pushStorage: PushStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.pushStorage = pushStorage
        subscribeForDeleteSubscription()
    }

    private func subscribeForDeleteSubscription() {
        let protocolMethod = PushDeleteProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushDeleteParams>) in
                logger.debug("Peer deleted subscription")
                let topic = payload.topic
                networkingInteractor.unsubscribe(topic: topic)
                Task(priority: .high) {
                    try await pushStorage.deleteSubscription(topic: topic)
                }
                kms.deleteSymmetricKey(for: topic)
            }.store(in: &publishers)
    }
}
