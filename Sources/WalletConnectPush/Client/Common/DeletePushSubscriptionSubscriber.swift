import Foundation
import Combine
import WalletConnectKMS
import WalletConnectPairing

class DeletePushSubscriptionSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    var onDelete: ((String) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        subscribeForDeleteSubscription()
    }

    private func subscribeForDeleteSubscription() {
        let protocolMethod = PushDeleteProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushDeleteParams>) in
                logger.debug("Peer deleted subscription")
                onDelete?(payload.topic)
            }.store(in: &publishers)
    }
}
