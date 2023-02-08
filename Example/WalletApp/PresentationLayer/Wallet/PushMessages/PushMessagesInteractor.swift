import WalletConnectPush
import Combine

final class PushMessagesInteractor {

    let subscription: PushSubscription
//    var pushMessagesPublisher: AnyPublisher<[PushMessage], Never> {
//        return Push.wallet.pushMessagesPublisher
//    }

    init(subscription: PushSubscription) {
        self.subscription = subscription
    }

    func getPushMessages() -> [PushMessage] {
        print(subscription.topic)
        return Push.wallet.getMessageHistory(topic: subscription.topic)
    }
}
