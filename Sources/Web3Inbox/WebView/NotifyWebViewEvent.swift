import Foundation

enum NotifyWebViewEvent: String {
    case update
    case subscribe
    case getActiveSubscriptions
    case getMessageHistory
    case deleteSubscription
    case deleteNotifyMessage
    case register
}
