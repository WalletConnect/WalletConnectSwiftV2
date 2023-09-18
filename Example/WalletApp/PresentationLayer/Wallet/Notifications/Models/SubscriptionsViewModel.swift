import Foundation
import WalletConnectNotify

struct SubscriptionsViewModel: Identifiable {
    let subscription: NotifySubscription

    var id: String {
        return subscription.topic
    }

    var imageUrl: URL? {
        return try? subscription.metadata.icons.first?.asURL()
    }

    var title: String {
        return subscription.metadata.name
    }

    var subtitle: String {
        return subscription.metadata.description
    }

    var url: String {
        return subscription.metadata.url
    }
}
