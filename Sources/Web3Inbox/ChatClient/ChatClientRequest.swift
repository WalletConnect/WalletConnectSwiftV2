import Foundation

enum ChatClientRequest: String {
    case chatInvite = "chat_invite"
    case chatThread = "chat_thread"
    case setAccount = "setAccount"

    var method: String {
        return rawValue
    }
}
