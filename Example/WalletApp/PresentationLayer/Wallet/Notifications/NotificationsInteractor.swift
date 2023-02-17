import WalletConnectPush
import Combine

final class NotificationsInteractor {

    var subscriptionsPublisher: AnyPublisher<[PushSubscription], Never> {
        return Push.wallet.subscriptionsPublisher
    }

    func getSubscriptions() -> [PushSubscription] {
        let subs = Push.wallet.getActiveSubscriptions()
        return subs
    }

    func removeSubscription(_ subscription: PushSubscription) async {
        do {
            try await Push.wallet.deleteSubscription(topic: subscription.topic)
        } catch {
            print(error)
        }
    }
}
