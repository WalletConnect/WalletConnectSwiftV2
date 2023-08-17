import WalletConnectNotify
import Combine

final class NotificationsInteractor {

    var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return Notify.wallet.subscriptionsPublisher
    }

    func getSubscriptions() -> [NotifySubscription] {
        let subs = Notify.wallet.getActiveSubscriptions()
        return subs
    }

    func removeSubscription(_ subscription: NotifySubscription) async {
        do {
            try await Notify.wallet.deleteSubscription(topic: subscription.topic)
        } catch {
            print(error)
        }
    }
}
