import Foundation
import WalletConnectNotify

typealias SubscriptionScope = [String: ScopeValue]

struct SubscriptionsViewModel: Identifiable {
    let subscription: NotifySubscription

    var id: String {
        return subscription.topic
    }

    var imageUrl: URL? {
        return try? subscription.metadata.icons.first?.asURL()
    }

    var subtitle: String {
        return subscription.metadata.description
    }

    var name: String {
        return subscription.metadata.name
    }

    var description: String {
        return subscription.metadata.description
    }

    var domain: String {
        return subscription.metadata.url
    }

    var scope: SubscriptionScope {
        return subscription.scope
    }
}
