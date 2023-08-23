import WalletConnectNotify
import Combine

final class PushMessagesInteractor {

    let subscription: NotifySubscription

    init(subscription: NotifySubscription) {
        self.subscription = subscription
    }

    var notifyMessagePublisher: AnyPublisher<NotifyMessageRecord, Never> {
        return Notify.instance.notifyMessagePublisher
    }
    
    func getPushMessages() -> [NotifyMessageRecord] {
        return Notify.instance.getMessageHistory(topic: subscription.topic)
    }

    func deletePushMessage(id: String) {
        Notify.instance.deleteNotifyMessage(id: id)
    }
}
