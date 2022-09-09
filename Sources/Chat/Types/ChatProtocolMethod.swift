import Foundation
import WalletConnectNetworking

enum ChatProtocolMethod: ProtocolMethod {
    case invite
    case message

    var requestTag: Int {
        switch self {
        case .invite:
            return 2000
        case .message:
            return 2002
        }
    }
    
    var responseTag: Int {
        switch self {
        case .invite:
            return 2001
        case .message:
            return 2003
        }
    }

    var method: String {
        switch self {
        case .invite:
            return "wc_chatInvite"
        case .message:
            return "wc_chatMessage"
        }
    }
}
