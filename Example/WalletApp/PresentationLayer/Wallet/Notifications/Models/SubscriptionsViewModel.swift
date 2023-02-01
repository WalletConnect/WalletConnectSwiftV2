import Foundation
import WalletConnectPush

struct SubscriptionsViewModel: Identifiable {
    let subscription: WalletConnectPush.PushSubscription

    var id: String {
        return subscription.topic
    }

    var imageUrl: String {
        return subscription.metadata.url
    }

    var title: String {
        return subscription.metadata.name
    }

    var subtitle: String {
        return subscription.metadata.description
    }
}
