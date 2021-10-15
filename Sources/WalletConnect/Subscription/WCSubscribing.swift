
import Foundation
import Combine

protocol WCSubscribing: AnyObject {
    var onRequestSubscription: ((WCRequestSubscriptionPayload)->())? {get set}
    func setSubscription(topic: String)
    func getSubscription(topic: String) -> String?
    func removeSubscription(topic: String)
}

class WCSubscriber: WCSubscribing {
    private var relay: Relaying
    var subscriptions: [String: String] = [:]
    var onRequestSubscription: ((WCRequestSubscriptionPayload)->())?
    private let concurrentQueue = DispatchQueue(label: "wc subscriber queue: \(UUID().uuidString)",
                                                attributes: .concurrent)
    private var publishers = [AnyCancellable]()
    private let logger: BaseLogger

    init(relay: Relaying,
         logger: BaseLogger) {
        self.relay = relay
        self.logger = logger
        setSubscribingForPayloads()
    }

    // MARK: - Sequence Subscribing Interface

    func setSubscription(topic: String) {
        logger.debug("Setting Subscription...")
        do {
            let _ = try relay.subscribe(topic: topic, completion: { [unowned self] result in
                switch result {
                case .success(let subscriptionId):
                    self.concurrentQueue.async(flags: .barrier) { [weak self] in
                        self?.subscriptions[topic] = subscriptionId
                    }
                case .failure(let error):
                    logger.error("Could not subscribe for topic: \(topic), error: \(error)")
                }
            })
        } catch {
            logger.error("Could not subscribe for topic: \(topic), error: \(error)")
        }
    }

    /// - returns: subscription id
    func getSubscription(topic: String) -> String? {
        concurrentQueue.sync {
            return subscriptions[topic]
        }
    }
    
    func removeSubscription(topic: String) {
        logger.debug("Removing subscription for topic: \(topic)")
        guard let subscriptionId = getSubscription(topic: topic) else {
            logger.error("Cannot unsubscribe on topic: \(topic)")
            return
        }
        let _ = try? relay.unsubscribe(topic: topic, id: subscriptionId) { [unowned self] result in
            switch result {
            case .success():
                logger.debug("Successfuly unsubscribed on topic: \(topic)")
                self.concurrentQueue.async(flags: .barrier) { [weak self] in
                    self?.subscriptions[topic] = nil
                }
            case .failure(_):
                logger.error("Failed to remove subscription")
                return
            }
        }
    }
    
    private func setSubscribingForPayloads() {
        relay.clientSynchJsonRpcPublisher
            .filter {[weak self] in self?.subscriptions.values.contains($0.subscriptionId) ?? false}
            .sink { [weak self] subscriptionPayload in
                self?.onRequestSubscription?(subscriptionPayload)
            }.store(in: &publishers)
    }
}
