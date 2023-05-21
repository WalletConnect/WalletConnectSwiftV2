import Foundation

enum PushClientRequest: String {
    case pushRequest = "push_request"
    case pushMessage = "push_message"
    case pushUpdate = "push_update"
    case pushDelete = "push_delete"
    case pushSubscription = "push_subscription"

    var method: String {
        return rawValue
    }
}
