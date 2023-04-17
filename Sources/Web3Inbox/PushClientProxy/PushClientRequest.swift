import Foundation

enum PushClientRequest: String {
    case pushRequest = "push_request"
    case pushMessage = "push-message"

    var method: String {
        return rawValue
    }
}
