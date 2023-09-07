import Foundation

public struct NotifyDeleteParams: Codable {
    let code: Int
    let message: String

    static var userDisconnected: NotifyDeleteParams {
        return NotifyDeleteParams(code: 6000, message: "User Disconnected")
    }
}
