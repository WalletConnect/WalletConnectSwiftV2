import Foundation

protocol SubscriptionsTracking {
    func setSubscription(for topic: String, id: String)
    func getSubscription(for topic: String) -> String?
    func removeSubscription(for topic: String)
    func isSubscribed() -> Bool
}

public final class SubscriptionsTracker: SubscriptionsTracking {
    private var subscriptions: [String: String] = [:]
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.subscriptions_tracker", attributes: .concurrent)

    func setSubscription(for topic: String, id: String) {
        concurrentQueue.async(flags: .barrier) {
            self.subscriptions[topic] = id
        }
    }

    func getSubscription(for topic: String) -> String? {
        var result: String?
        concurrentQueue.sync {
            result = self.subscriptions[topic]
        }
        return result
    }

    func removeSubscription(for topic: String) {
        concurrentQueue.async(flags: .barrier) {
            self.subscriptions[topic] = nil
        }
    }

    func isSubscribed() -> Bool {
        var result = false
        concurrentQueue.sync {
            result = !self.subscriptions.isEmpty
        }
        return result
    }
}

#if DEBUG
final class SubscriptionsTrackerMock: SubscriptionsTracking {
    var isSubscribedReturnValue: Bool = false
    private var subscriptions: [String: String] = [:]

    func setSubscription(for topic: String, id: String) {
        subscriptions[topic] = id
    }

    func getSubscription(for topic: String) -> String? {
        return subscriptions[topic]
    }

    func removeSubscription(for topic: String) {
        subscriptions[topic] = nil
    }

    func isSubscribed() -> Bool {
        return isSubscribedReturnValue
    }

    func reset() {
        subscriptions.removeAll()
        isSubscribedReturnValue = false
    }
}
#endif
