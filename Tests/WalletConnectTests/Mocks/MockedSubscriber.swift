
import Foundation
@testable import WalletConnect

class MockedSubscriber: WCSubscribing {
    var subscriptions: [String: String] = [:]
    var onRequestSubscription: ((WCRequestSubscriptionPayload)->())?
    
    func setSubscription(topic: String) {
        subscriptions[topic] = UUID().uuidString
    }
    
    func getSubscription(topic: String) -> String? {
        fatalError()
    }
    
    func removeSubscription(topic: String) {
        subscriptions[topic] = nil
    }
}
