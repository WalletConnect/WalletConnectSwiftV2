import Foundation
import Combine

class NotifySubscriptionsChangedRequestSubscriber {
    private let keyserver: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         identityClient: IdentityClient,
         logger: ConsoleLogging,
         notifyStorage: NotifyStorage,
         notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.identityClient = identityClient
        self.notifyStorage = notifyStorage
        self.notifySubscriptionsBuilder = notifySubscriptionsBuilder
        subscribeForNofifyChangedRequests()
    }


    private func subscribeForNofifyChangedRequests() {
        let protocolMethod =  NotifySubscriptionsChangedProtocolMethod()

        networkingInteractor.requestSubscription(on: protocolMethod).sink { [unowned self]  (payload: RequestSubscriptionPayload<NotifySubscriptionsChangedRequestPayload.Wrapper>) in


            Task(priority: .high) {
                logger.debug("Received Subscriptions Changed Request")

                guard
                    let (jwtPayload, _) = try? NotifySubscriptionsChangedRequestPayload.decodeAndVerify(from: payload.request)
                else { fatalError() /* TODO: Handle error */ }

                // todo varify signature with notify server diddoc authentication key

                let subscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(jwtPayload.subscriptions)

                notifyStorage.replaceAllSubscriptions(subscriptions)

                var logProperties = [String: String]()
                for (index, subscription) in subscriptions.enumerated() {
                    let key = "subscription_\(index + 1)"
                    logProperties[key] = subscription.topic
                }

                logger.debug("Updated Subscriptions by Subscriptions Changed Request", properties: logProperties)

                try await respond(topic: payload.topic, account: jwtPayload.account, rpcId: payload.id)

            }

        }.store(in: &publishers)
    }

    private func respond(topic: String, account: Account, rpcId: RPCID) async throws {

        let receiptPayload = NotifySubscriptionsChangedResponsePayload(keyserver: keyserver)

        let wrapper = try identityClient.signAndCreateWrapper(
            payload: receiptPayload,
            account: account
        )

        let response = RPCResponse(id: rpcId, result: wrapper)
        try await networkingInteractor.respond(
            topic: topic,
            response: response,
            protocolMethod: NotifySubscriptionsChangedProtocolMethod()
        )
    }

}
