
import Foundation
import Combine

protocol WCSubscribing: AnyObject {
    var onReceivePayload: ((WCRequestSubscriptionPayload)->())? {get set}
    func setSubscription(topic: String)
    func removeSubscription(topic: String)
}

class WCSubscriber: WCSubscribing {
    
    var onReceivePayload: ((WCRequestSubscriptionPayload)->())?
    
    private var relay: WalletConnectRelaying
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.wc_subscriber",
                                                attributes: .concurrent)
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogger
    var topics: [String] = []

    init(relay: WalletConnectRelaying,
         logger: ConsoleLogger) {
        self.relay = relay
        self.logger = logger
        setSubscribingForPayloads()
    }

    // MARK: - Sequence Subscribing Interface

    func setSubscription(topic: String) {
        logger.debug("Setting Subscription...")
        concurrentQueue.sync {
            topics.append(topic)
        }
        relay.subscribe(topic: topic)
    }
    
    func getTopics() -> [String] {
        concurrentQueue.sync {
            return topics
        }
    }
    
    func removeSubscription(topic: String) {
        concurrentQueue.sync {
            topics.removeAll {$0 == topic}
        }
        relay.unsubscribe(topic: topic)
    }
    
    private func setSubscribingForPayloads() {
        relay.wcRequestPublisher
            .filter {[weak self] in self?.getTopics().contains($0.topic) ?? false}
            .sink { [weak self] subscriptionPayload in
                self?.onReceivePayload?(subscriptionPayload)
            }.store(in: &publishers)
    }
}
