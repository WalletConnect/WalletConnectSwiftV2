import Foundation
import WalletConnectNotify

typealias SubscriptionScope = [String: ScopeValue]

struct SubscriptionsViewModel: Identifiable {
    let subscription: NotifySubscription
    let messages: [NotifyMessageRecord]?

    init(subscription: NotifySubscription, messages: [NotifyMessageRecord]? = nil) {
        self.subscription = subscription
        self.messages = messages
    }

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

    var messagesCount: Int {
        return messages?.count ?? 0
    }

    var hasMessage: Bool {
        return messagesCount != 0
    }
}
