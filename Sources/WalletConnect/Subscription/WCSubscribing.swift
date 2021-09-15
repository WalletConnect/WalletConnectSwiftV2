
import Foundation

protocol WCSubscribing {
    func setSubscription(topic: String)
    func getSubscription(topic: String) -> String?
    func removeSubscription(topic: String)
}

class WCSubscriber: WCSubscribing {
    private var relay: Relaying
    var subscriptions: [String: String] = [:]

    init(relay: Relaying) {
        self.relay = relay
    }

    // MARK: - Sequence Subscribing Interface

    func setSubscription(topic: String) {
        Logger.debug("Setting Subscription...")
        do {
            let _ = try relay.subscribe(topic: topic, completion: { [unowned self] result in
                switch result {
                case .success(let subscriptionId):
                    self.subscriptions[topic] = subscriptionId
                case .failure(let error):
                    Logger.error("Could not subscribe for topic: \(topic), error: \(error)")
                }
            })
        } catch {
            Logger.error("Could not subscribe for topic: \(topic), error: \(error)")
        }
    }
    
    /// - returns: subscription id
    func getSubscription(topic: String) -> String? {
        return subscriptions[topic]
    }
    
    func removeSubscription(topic: String) {
        Logger.debug("Removing subscription for topic: \(topic)")
        guard let subscriptionId = subscriptions[topic] else {
            Logger.error("Cannot unsubscribe on topic: \(topic)")
            return
        }
        let _ = try? relay.unsubscribe(topic: topic, id: subscriptionId) { [unowned self] result in
            switch result {
            case .success():
                Logger.debug("Successfuly unsubscribed on topic: \(topic)")
                self.subscriptions[topic] = nil
            case .failure(_):
                Logger.error("Failed to remove subscription")
                return
            }
        }
    }
}
