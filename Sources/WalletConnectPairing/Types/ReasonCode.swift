import Foundation
import WalletConnectNetworking

enum ReasonCode: Reason, Codable {
    case userDisconnected

    var code: Int {
        return 6000
    }

    var message: String {
        return "User Disconnected"
    }
}
