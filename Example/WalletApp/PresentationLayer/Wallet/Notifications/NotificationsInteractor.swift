import WalletConnectPush

final class NotificationsInteractor {

    func getSubscriptions() -> [PushSubscription] {
        Push.wallet.getActiveSubscriptions()
    }
}
