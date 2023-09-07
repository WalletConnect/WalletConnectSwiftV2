import Foundation
import Combine

class DeleteNotifySubscriptionSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
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
        let protocolMethod = NotifyDeleteProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<NotifyDeleteResponsePayload.Wrapper>) in

                guard let (_, _) = try? NotifyDeleteResponsePayload.decodeAndVerify(from: payload.request)
                else { fatalError() /* TODO: Handle error */ }

                logger.debug("Peer deleted subscription")
            }.store(in: &publishers)
    }
}
