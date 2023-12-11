import Foundation
@testable import WalletConnectNotify

class MockNotifyStoring: NotifyStoring {

    var subscriptions: [NotifySubscription]

    init(subscriptions: [NotifySubscription]) {
        self.subscriptions = subscriptions
    }

    func getSubscriptions(account: Account) -> [NotifySubscription] {
        return subscriptions.filter { $0.account == account }
    }

    func getSubscription(topic: String) -> NotifySubscription? {
        return subscriptions.first { $0.topic == topic }
    }

    func getAllSubscriptions() -> [WalletConnectNotify.NotifySubscription] {
        return subscriptions
    }

    func setSubscription(_ subscription: NotifySubscription) {
        if let index = subscriptions.firstIndex(where: { $0.topic == subscription.topic }) {
            subscriptions[index] = subscription
        } else {
            subscriptions.append(subscription)
        }
    }

    func clearDatabase(account: WalletConnectUtils.Account) {
        subscriptions = subscriptions.filter { $0.account != account }
    }

    func deleteSubscription(topic: String) throws {
        subscriptions.removeAll(where: { $0.topic == topic })
    }
}
