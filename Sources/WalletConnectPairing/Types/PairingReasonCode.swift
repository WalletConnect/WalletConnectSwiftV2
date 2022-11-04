import Foundation

enum PairingReasonCode: Reason, Codable {
    case userDisconnected

    var code: Int {
        return 6000
    }

    var message: String {
        return "User Disconnected"
    }
}
