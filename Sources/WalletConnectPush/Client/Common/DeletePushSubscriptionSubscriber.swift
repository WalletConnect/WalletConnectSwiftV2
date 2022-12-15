import Foundation
import Combine
import WalletConnectKMS
import WalletConnectPairing

class DeletePushSubscriptionSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let pushSubscriptionStore: CodableStore<PushSubscription>

    var onDelete: ((String) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         pushSubscriptionStore: CodableStore<PushSubscription>
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.pushSubscriptionStore = pushSubscriptionStore
        subscribeForDeleteSubscription()
    }

    private func subscribeForDeleteSubscription() {
        let protocolMethod = PushDeleteProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushDeleteParams>) in
                logger.debug("Peer deleted subscription")
                let topic = payload.topic
                networkingInteractor.unsubscribe(topic: topic)
                pushSubscriptionStore.delete(forKey: topic)
                kms.deleteSymmetricKey(for: topic)
                onDelete?(payload.topic)
            }.store(in: &publishers)
    }
}
