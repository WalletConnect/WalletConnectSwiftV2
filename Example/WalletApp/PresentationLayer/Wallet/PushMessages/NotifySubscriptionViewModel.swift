import Foundation
import WalletConnectNotify

struct NotifySubscriptionViewModel {

    let subscription: NotifySubscription

    var name: String {
        return subscription.metadata.name
    }

    var description: String {
        return subscription.metadata.description
    }

    var domain: String {
        return subscription.metadata.url
    }

    var iconUrl: URL? {
        return try? subscription.metadata.icons.first?.asURL()
    }
}
