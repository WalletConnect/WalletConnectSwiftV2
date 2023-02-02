import WalletConnectPush

final class NotificationsInteractor {

    func getSubscriptions() -> [PushSubscription] {
        Push.wallet.getActiveSubscriptions()
    }

    func removeSubscription(_ subscription: PushSubscription) async {
        do {
            try await Push.wallet.delete(topic: subscription.topic)
        } catch {
            print(error)
        }
    }
}
