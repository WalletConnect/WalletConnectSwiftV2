import WalletConnectNotify
import Combine

final class NotificationsInteractor {

    var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return Notify.instance.subscriptionsPublisher
    }

    func getSubscriptions() -> [NotifySubscription] {
        let subs = Notify.instance.getActiveSubscriptions()
        return subs
    }

    func removeSubscription(_ subscription: NotifySubscription) async {
        do {
            try await Notify.instance.deleteSubscription(topic: subscription.topic)
        } catch {
            print(error)
        }
    }
}
