import WalletConnectNotify
import Combine

final class SubscriptionInteractor {

    let subscription: NotifySubscription

    init(subscription: NotifySubscription) {
        self.subscription = subscription
    }

    var messagesPublisher: AnyPublisher<[NotifyMessageRecord], Never> {
        return Notify.instance.messagesPublisher(topic: subscription.topic)
    }

    var subscriptionPublisher: AnyPublisher<[NotifySubscription], Never> {
        return Notify.instance.subscriptionsPublisher
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
