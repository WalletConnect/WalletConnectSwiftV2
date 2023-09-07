import Foundation
import Combine

class NotifyWatchSubscriptionsResponseSubscriber {
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
        subscribeForWatchSubscriptionsResponse()
    }


    private func subscribeForWatchSubscriptionsResponse() {

        let protocolMethod = NotifySubscribeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<NotifyWatchSubscriptionsPayload.Wrapper, NotifyWatchSubscriptionsResponsePayload.Wrapper>) in
                Task(priority: .high) {
                    logger.debug("Received Notify Watch Subscriptions response")

                    guard
                        let (responsePayload, _) = try? NotifyWatchSubscriptionsResponsePayload.decodeAndVerify(from: payload.response)
                    else { fatalError() /* TODO: Handle error */ }

                    // todo varify signature with notify server diddoc authentication key

                    let subscriptions = try await buildSubscriptions(responsePayload.subscriptions)

                    notifyStorage.replaceAllSubscriptions(subscriptions)

                    var logProperties = [String: String]()
                    for (index, subscription) in subscriptions.enumerated() {
                        let key = "subscription_\(index + 1)"
                        logProperties[key] = subscription.topic
                    }

                    logger.debug("Updated Subscriptions by Watch Subscriptions Update", properties: logProperties)

                }
            }.store(in: &publishers)
    }

    private func buildSubscriptions(_ notifyServerSubscriptions: [NotifyServerSubscription]) async throws -> [NotifySubscription] {
        var result = [NotifySubscription]()

        for subscription in notifyServerSubscriptions {
            let scope = try await buildScope(selectedScope: subscription.scope, dappUrl: subscription.dappUrl)
            guard let metadata = try? await subscriptionScopeProvider.getMetadata(dappUrl: subscription.dappUrl),
                  let topic = try? SymmetricKey(hex: subscription.symKey).derivedTopic() else { continue }

            let notifySubscription = NotifySubscription(topic: topic,
                                                        account: subscription.account,
                                                        relay: RelayProtocolOptions(protocol: "irn", data: nil),
                                                        metadata: metadata,
                                                        scope: scope,
                                                        expiry: subscription.expiry,
                                                        symKey: subscription.symKey)
            result.append(notifySubscription)
        }

        return result
    }


    private func buildScope(selectedScope: [String], dappUrl: String) async throws -> [String: ScopeValue] {
        let availableScope = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: dappUrl)
        return availableScope.reduce(into: [:]) {
            $0[$1.name] = ScopeValue(description: $1.description, enabled: selectedScope.contains($1.name))
        }
    }
}
