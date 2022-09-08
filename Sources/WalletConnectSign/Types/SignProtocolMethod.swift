import Foundation
import JSONRPC
import WalletConnectPairing
import WalletConnectUtils
import WalletConnectNetworking

enum SignProtocolMethod: ProtocolMethod {
    case pairingDelete
    case pairingPing
    case sessionPropose
    case sessionSettle
    case sessionUpdate
    case sessionExtend
    case sessionDelete
    case sessionRequest
    case sessionPing
    case sessionEvent

    var method: String {
        switch self {
        case .pairingDelete:
            return "wc_pairingDelete"
        case .pairingPing:
            return "wc_pairingPing"
        case .sessionPropose:
            return "wc_sessionPropose"
        case .sessionSettle:
            return "wc_sessionSettle"
        case .sessionUpdate:
            return "wc_sessionUpdate"
        case .sessionExtend:
            return "wc_sessionExtend"
        case .sessionDelete:
            return "wc_sessionDelete"
        case .sessionRequest:
            return "wc_sessionRequest"
        case .sessionPing:
            return "wc_sessionPing"
        case .sessionEvent:
            return "wc_sessionEvent"
        }
    }

    var requestTag: Int {
        switch self {
        case .pairingDelete:
            return 1000
        case .pairingPing:
            return 1002
        case .sessionPropose:
            return 1100
        case .sessionSettle:
            return 1102
        case .sessionUpdate:
            return 1104
        case .sessionExtend:
            return 1106
        case .sessionDelete:
            return 1112
        case .sessionRequest:
            return 1108
        case .sessionPing:
            return 1114
        case .sessionEvent:
            return 1110
        }
    }

    var responseTag: Int {
        return requestTag + 1
    }
}
