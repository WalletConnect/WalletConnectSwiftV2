import Foundation

enum NotifyClientRequest: String {
    case notifyMessage = "push_message"
    case notifyUpdate = "push_update"
    case notifyDelete = "push_delete"
    case notifySubscription = "push_subscription"

    var method: String {
        return rawValue
    }
}
