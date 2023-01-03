import Foundation
import WalletConnectChat

enum WebViewRequest: Codable {
    case getInvites(account: String)
}

enum WebViewResponse: Codable, WebViewScript {
    case getInvites(invites: [Invite])

    var command: String {
        switch self {
        case .getInvites:
            return "getInvites"
        }
    }
}
