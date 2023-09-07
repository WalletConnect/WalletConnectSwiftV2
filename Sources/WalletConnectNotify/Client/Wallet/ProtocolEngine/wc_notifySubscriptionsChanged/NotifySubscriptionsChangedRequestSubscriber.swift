import Foundation
import Combine

class NotifySubscriptionsChangedRequestSubscriber {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let subscriptionScopeProvider: SubscriptionScopeProvider

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         notifyStorage: NotifyStorage,
         subscriptionScopeProvider: SubscriptionScopeProvider
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
        self.subscriptionScopeProvider = subscriptionScopeProvider
        subscribeForNofifyChangedRequests()
    }


    private func subscribeForNofifyChangedRequests() {
        let protocolMethod =  NotifySubscriptionsChangedRequest()

        networkingInteractor.requestSubscription(on: protocolMethod).sink { [unowned self]  (payload: RequestSubscriptionPayload<NotifySubscriptionsChangedRequestPayload.Wrapper>) in
            <#code#>
        }
    }
}
