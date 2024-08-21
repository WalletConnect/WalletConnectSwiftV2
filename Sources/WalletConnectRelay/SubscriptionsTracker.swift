import Foundation

public final class SubscriptionsTracker {
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
