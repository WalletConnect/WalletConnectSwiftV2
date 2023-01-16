import Foundation

enum ChatClientRequest: String {
    case chatInvite = "chat_invite"
    case chatThread = "chat_thread"
    case chatMessage = "chat_message"
    case setAccount = "setAccount"

    var method: String {
        return rawValue
    }
}
