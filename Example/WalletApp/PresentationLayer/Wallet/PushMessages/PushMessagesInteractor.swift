import WalletConnectPush
import Combine

final class PushMessagesInteractor {

    let subscription: PushSubscription

    init(subscription: PushSubscription) {
        self.subscription = subscription
    }

    var pushMessagePublisher: AnyPublisher<PushMessageRecord, Never> {
        return Push.wallet.pushMessagePublisher
    }
    
    func getPushMessages() -> [PushMessageRecord] {
        return Push.wallet.getMessageHistory(topic: subscription.topic)
    }

    func deletePushMessage(id: String) {
        Push.wallet.deletePushMessage(id: id)
    }
}
