import WalletConnectNotify
import Combine

final class PushMessagesInteractor {

    let subscription: NotifySubscription

    init(subscription: NotifySubscription) {
        self.subscription = subscription
    }

    var notifyMessagePublisher: AnyPublisher<NotifyMessageRecord, Never> {
        return Notify.wallet.notifyMessagePublisher
    }
    
    func getPushMessages() -> [NotifyMessageRecord] {
        return Notify.wallet.getMessageHistory(topic: subscription.topic)
    }

    func deletePushMessage(id: String) {
        Notify.wallet.deleteNotifyMessage(id: id)
    }
}
