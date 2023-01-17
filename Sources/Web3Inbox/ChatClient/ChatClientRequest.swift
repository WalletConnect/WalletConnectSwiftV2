import Foundation

enum ChatClientRequest: String {
    case chatInvite = "chat_invite"
    case chatThread = "chat_joined"
    case chatMessage = "chat_message"
    case setAccount = "setAccount"

    var method: String {
        return rawValue
    }
}
