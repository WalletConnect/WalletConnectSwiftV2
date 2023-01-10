import Foundation

enum ChatClientRequest: String {
    case chatInvite = "chat_invite"
    case setAccount = "setAccount"

    var method: String {
        return rawValue
    }
}
