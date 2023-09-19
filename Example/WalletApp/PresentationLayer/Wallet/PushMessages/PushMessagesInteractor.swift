import WalletConnectNotify
import Combine

final class PushMessagesInteractor {

    let subscription: NotifySubscription

    init(subscription: NotifySubscription) {
        self.subscription = subscription
    }

    var messagesPublisher: AnyPublisher<[NotifyMessageRecord], Never> {
        return Notify.instance.messagesPublisher(topic: subscription.topic)
    }
    
    func getPushMessages() -> [NotifyMessageRecord] {
        return Notify.instance.getMessageHistory(topic: subscription.topic)
    }

    func deletePushMessage(id: String) {
        Notify.instance.deleteNotifyMessage(id: id)
    }

    func deleteSubscription(_ subscription: NotifySubscription) {
        Task(priority: .high) {
            try await Notify.instance.deleteSubscription(topic: subscription.topic)
        }
    }
}
