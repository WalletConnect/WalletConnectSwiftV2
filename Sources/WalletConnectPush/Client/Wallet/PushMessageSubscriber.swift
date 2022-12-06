import Foundation
import Combine
import WalletConnectKMS

class PushMessageSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    var onResponse: ((_ id: RPCID, _ result: Result<PushSubscription, PairError>) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        subscribeForPushMessages()
    }

    private func subscribeForPushMessages() {


        let protocolMethod = PushMessageProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushMessage>) in
                logger.debug("Received Push Message")


            }.store(in: &publishers)

    }
}
