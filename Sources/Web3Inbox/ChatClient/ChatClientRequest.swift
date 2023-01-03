import Foundation
import WalletConnectChat

enum ChatClientRequest: Codable, WebViewScript {
    case chatInvite(invite: Invite)

    var command: String {
        switch self {
        case .chatInvite:
            return "chatInvite"
        }
    }
}
