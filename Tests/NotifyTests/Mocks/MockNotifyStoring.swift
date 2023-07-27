import Foundation
@testable import WalletConnectNotify

class MockNotifyStoring: NotifyStoring {
    var subscriptions: [NotifySubscription]

    init(subscriptions: [NotifySubscription]) {
        self.subscriptions = subscriptions
    }

    func getSubscriptions() -> [NotifySubscription] {
        return subscriptions
    }

    func getSubscription(topic: String) -> NotifySubscription? {
        return subscriptions.first { $0.topic == topic }
    }

    func setSubscription(_ subscription: NotifySubscription) async throws {
        if let index = subscriptions.firstIndex(where: { $0.topic == subscription.topic }) {
            subscriptions[index] = subscription
        } else {
            subscriptions.append(subscription)
        }
    }

    func deleteSubscription(topic: String) async throws {
        subscriptions.removeAll(where: { $0.topic == topic })
    }
}
