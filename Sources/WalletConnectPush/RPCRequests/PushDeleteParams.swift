import Foundation

public struct PushDeleteParams: Codable {
    let code: Int
    let message: String

    static var userDisconnected: PushDeleteParams {
        return PushDeleteParams(code: 6000, message: "User Disconnected")
    }
}
