import Foundation
import WalletConnectNetworking

enum PushProtocolMethod: String, ProtocolMethod {
    case propose = "wc_pushPropose"

    var method: String {
        return self.rawValue
    }

    var requestTag: Int {
        switch self {
        case .propose:
            return 3000
        }
    }

    var responseTag: Int {
        switch self {
        case .propose:
            return 3001
        }
    }
}

struct PushRequestParams: Codable {}
