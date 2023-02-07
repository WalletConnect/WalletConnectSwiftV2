import WalletConnectPush

final class PushMessagesInteractor {

    let subscription: PushSubscription
    init(subscription: PushSubscription) {
        self.subscription = subscription
    }
}
