import Foundation

enum PushWebViewEvent: String {
    case approve
    case update
    case reject
    case subscribe
    case getActiveSubscriptions
    case getMessageHistory
    case deleteSubscription
    case deletePushMessage
}
