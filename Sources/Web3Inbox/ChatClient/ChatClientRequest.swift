import Foundation

enum ChatClientRequest: String {
    case chatInvite

    var method: String {
        return rawValue
    }
}
