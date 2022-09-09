import Foundation
import WalletConnectNetworking

enum AuthProtocolMethod: String, ProtocolMethod {
    case authRequest = "wc_authRequest"
    case pairingDelete = "wc_pairingDelete"
    case pairingPing = "wc_pairingPing"

    var method: String {
        return self.rawValue
    }

    var requestTag: Int {
        switch self {
        case .authRequest:
            return 3000
        case .pairingDelete:
            return 1000
        case .pairingPing:
            return 1002
        }
    }

    var responseTag: Int {
        switch self {
        case .authRequest:
            return 3001
        case .pairingDelete:
            return 1001
        case .pairingPing:
            return 1003
        }
    }
}
