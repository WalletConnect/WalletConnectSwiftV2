import Foundation
import WalletConnectChat

enum WebViewRequestMethod: String {
    case getInvites
}

enum WebViewRequest: Codable {
    case getInvites(account: String)
}

enum WebViewResponse: Codable {
    case getInvites(invites: [Invite])
}
