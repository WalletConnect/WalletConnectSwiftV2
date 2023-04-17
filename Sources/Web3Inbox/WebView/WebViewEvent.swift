import Foundation

enum WebViewEvent: String {
    case getReceivedInvites
    case getSentInvites
    case getThreads
    case register
    case resolve
    case getMessages
    case message
    case accept
    case reject
    case invite
}

enum PushWebViewEvent: String {
    case approve
    case reject
    case subscribe
    case getActiveSubscriptions
    case getMessageHistory
    case deleteSubscription
    case deletePushMessage
}
