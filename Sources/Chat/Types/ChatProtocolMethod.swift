import Foundation
import WalletConnectNetworking

enum ChatProtocolMethod: ProtocolMethod {
    case invite
    case message

    var tag: Int {
        switch self {
        case .invite:
            return 2002
        case .message:
            return 2002
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
