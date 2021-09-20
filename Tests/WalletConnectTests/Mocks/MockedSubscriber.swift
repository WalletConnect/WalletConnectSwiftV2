
import Foundation
@testable import WalletConnect

class MockedSubscriber: WCSubscribing {
    var onSubscription: ((WCSubscriptionPayload)->())?
    
    func setSubscription(topic: String) {
    }
    
    func getSubscription(topic: String) -> String? {
        fatalError()
    }
    
    func removeSubscription(topic: String) {
    }
}
