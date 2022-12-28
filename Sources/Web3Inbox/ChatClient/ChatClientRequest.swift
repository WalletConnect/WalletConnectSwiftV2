import Foundation
import WalletConnectChat

enum ChatClientRequestMethod: String {
    case chatInvites
}

enum ChatClientRequest: Codable {
    case chatInvite(invite: Invite)
}
