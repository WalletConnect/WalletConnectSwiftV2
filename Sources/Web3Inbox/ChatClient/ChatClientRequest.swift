import Foundation

enum ChatClientRequest: String {
    case chatInvite = "chat_invite"
    case chatInviteAccepted = "chat_invite_accepted"
    case chatInviteRejected = "chat_invite_rejected"
    case chatLeft = "chat_left" // TODO: Implement me
    case chatMessage = "chat_message"
    case setAccount = "setAccount"

    var method: String {
        return rawValue
    }
}
