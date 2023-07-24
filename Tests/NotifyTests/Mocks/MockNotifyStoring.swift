
import Foundation
@testable import WalletConnectNotify

class MockPushStoring: PushStoring {
    var subscriptions: [PushSubscription]

    init(subscriptions: [PushSubscription]) {
        self.subscriptions = subscriptions
    }

    func getSubscriptions() -> [PushSubscription] {
        return subscriptions
    }

    func getSubscription(topic: String) -> PushSubscription? {
        return subscriptions.first { $0.topic == topic }
    }

    func setSubscription(_ subscription: PushSubscription) async throws {
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
