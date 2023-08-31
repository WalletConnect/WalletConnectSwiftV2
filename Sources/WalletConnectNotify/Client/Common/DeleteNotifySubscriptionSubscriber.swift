import Foundation
import Combine

class DeleteNotifySubscriptionSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         notifyStorage: NotifyStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
        subscribeForDeleteSubscription()
    }

    private func subscribeForDeleteSubscription() {
        networkingInteractor.subscribeOnRequest(
            protocolMethod: NotifyDeleteProtocolMethod(),
            requestOfType: NotifyDeleteResponsePayload.Wrapper.self
        ) { [unowned self] payload in
            let (_, _) = try NotifyDeleteResponsePayload.decodeAndVerify(from: payload.request)
            logger.debug("Peer deleted subscription")
        }
    }
}
