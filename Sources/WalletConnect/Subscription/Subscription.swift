
import Foundation

protocol SequenceSubscribing {
    func set(topic: String, sequenceData: SequenceData)
    func get(topic: String) -> SequenceData?
    func remove(topic: String)
}

class Subscription: SequenceSubscribing {
    private var relay: Relaying
    var subscriptions: [String: SubscriptionParams] = [:]

    init(relay: Relaying) {
        self.relay = relay
    }

    // MARK: - Sequence Subscribing Interface

    func set(topic: String, sequenceData: SequenceData) {
        Logger.debug("Setting Subscription...")
        subscribeAndSet(topic: topic, sequenceData: sequenceData)
    }

    func get(topic: String) -> SequenceData? {
        Logger.debug("Getting Subscription...")
        if let subscription = subscriptions[topic] {
            Logger.debug("Subscription for a topic: \(topic) found")
            return subscription.sequence
        } else {
            Logger.error("Subscription for a topic: \(topic) not found")
            return nil
        }
    }
    
    func remove(topic: String) {
        Logger.debug("Removing subscription for topic: \(topic)")
        guard let subscriptionParams = subscriptions[topic] else {
            Logger.error("Cannot unsubscribe on topic: \(topic)")
            return
        }
        let _ = try? relay.unsubscribe(topic: topic, id: subscriptionParams.id) { [unowned self] result in
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
    
    // MARK: - Private
    
    private func subscribeAndSet(topic: String, sequenceData: SequenceData)  {
        do {
            let _ = try relay.subscribe(topic: topic, completion: { [unowned self] result in
                switch result {
                case .success(let subscriptionId):
                    let subscriptionParams = SubscriptionParams(id: subscriptionId, topic: topic, sequence: sequenceData)
                    self.subscriptions[topic] = subscriptionParams
                case .failure(let error):
                    Logger.error("Could not subscribe for topic: \(topic), error: \(error)")
                }
            })
        } catch {
            Logger.error("Could not subscribe for topic: \(topic), error: \(error)")
        }
    }
}
