import Foundation

enum NotifyClientRequest: String {
    case notifyMessage = "notify_message"
    case notifyUpdate = "notify_update"
    case notifyDelete = "notify_delete"
    case notifySubscription = "notify_subscription"
    case notifySubscriptionsChanged = "notify_subscriptions_changed"

    var method: String {
        return rawValue
    }
}
