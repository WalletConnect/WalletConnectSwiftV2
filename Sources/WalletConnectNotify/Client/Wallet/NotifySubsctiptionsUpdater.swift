import Foundation
import Combine

final class NotifySubsctiptionsUpdater {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let groupKeychainStorage: KeychainStorageProtocol

    private let subscriptionChangedSubject = PassthroughSubject<[NotifySubscription], Never>()

    var subscriptionChangedPublisher: AnyPublisher<[NotifySubscription], Never> {
        return subscriptionChangedSubject.eraseToAnyPublisher()
    }

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol, logger: ConsoleLogging, notifyStorage: NotifyStorage, groupKeychainStorage: KeychainStorageProtocol) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
        self.groupKeychainStorage = groupKeychainStorage
    }

    func update(subscriptions newSubscriptions: [NotifySubscription], for account: Account) async throws {
        let oldSubscriptions = notifyStorage.getSubscriptions(account: account)

        subscriptionChangedSubject.send(newSubscriptions)

        try Task.checkCancellation()

        let subscriptions = oldSubscriptions.difference(from: newSubscriptions)

        logger.debug("Received: \(newSubscriptions.count), changed: \(subscriptions.count)")

        if subscriptions.count > 0 {
            try notifyStorage.replaceAllSubscriptions(newSubscriptions)

            for subscription in newSubscriptions {
                let symKey = try SymmetricKey(hex: subscription.symKey)
                try groupKeychainStorage.add(symKey, forKey: subscription.topic)
                try kms.setSymmetricKey(symKey, for: subscription.topic)
            }

            let topicsToSubscribe = newSubscriptions.map { $0.topic }

            let oldTopics = Set(oldSubscriptions.map { $0.topic })
            let topicsToUnsubscribe = Array(oldTopics.subtracting(topicsToSubscribe))

            try await networkingInteractor.batchUnsubscribe(topics: topicsToUnsubscribe)
            try await networkingInteractor.batchSubscribe(topics: topicsToSubscribe)

            try Task.checkCancellation()

            logger.debug("Updated Subscriptions by Subscriptions Changed Request", properties: [
                "topics": newSubscriptions.map { $0.topic }.joined(separator: ",")
            ])
        }
    }
}
